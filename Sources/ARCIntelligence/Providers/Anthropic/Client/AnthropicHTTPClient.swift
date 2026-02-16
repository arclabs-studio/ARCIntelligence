//
//  AnthropicHTTPClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import ARCLogger
import ARCNetworking
import Foundation

/// Concrete implementation of `AnthropicAPIClient` using ARCNetworking for
/// standard requests and URLSession for streaming SSE.
final class AnthropicHTTPClient: AnthropicAPIClient, Sendable {
    // MARK: - Properties

    private let authentication: AnthropicAuthentication
    private let httpClient: HTTPClientProtocol
    private let session: URLSession
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "AnthropicHTTP")

    // MARK: - Constants

    private static let apiVersion = "2023-06-01"
    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.anthropic.com") else {
            fatalError("Invalid hardcoded Anthropic API URL")
        }
        return url
    }()

    // MARK: - Initialization

    init(authentication: AnthropicAuthentication,
         httpClient: HTTPClientProtocol = HTTPClient(),
         session: URLSession = .shared) {
        self.authentication = authentication
        self.httpClient = httpClient
        self.session = session
    }

    // MARK: - AnthropicAPIClient

    func sendMessage(_ request: AnthropicMessageRequest) async throws -> AnthropicMessageResponse {
        try validateAuthentication()

        let endpoint = AnthropicMessagesEndpoint(resolvedBaseURL: baseURL(),
                                                 resolvedHeaders: authHeaders(),
                                                 request: request)

        do {
            return try await httpClient.execute(endpoint)
        } catch let httpError as HTTPError {
            throw mapHTTPError(httpError)
        }
    }

    func streamMessage(_ request: AnthropicMessageRequest) -> AsyncThrowingStream<AnthropicStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task { [self] in
                do {
                    try validateAuthentication()

                    let urlRequest = try buildStreamingURLRequest(for: request)
                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    if let httpResponse = response as? HTTPURLResponse {
                        let isError = !(200 ... 299).contains(httpResponse.statusCode)
                        if isError {
                            let errorData = try await collectErrorData(from: bytes)
                            let error = mapHTTPStatusCode(httpResponse.statusCode, data: errorData)
                            continuation.finish(throwing: error)
                            return
                        }
                    }

                    let parser = AnthropicStreamParser()
                    let eventStream = parser.parse(bytes)

                    for try await event in eventStream {
                        continuation.yield(event)

                        if case .messageStop = event {
                            continuation.finish()
                            return
                        }
                    }

                    continuation.finish()
                } catch {
                    logger.error("Streaming failed", metadata: ["error": .public(error.localizedDescription)])
                    continuation.finish(throwing: mapError(error))
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func validateAuthentication() throws {
        switch authentication {
        case let .apiKey(key):
            guard !key.isEmpty else {
                throw IntelligenceError.providerNotConfigured("Anthropic API key is empty")
            }
        case let .aiProxy(partialKey, serviceURL):
            guard !partialKey.isEmpty, !serviceURL.isEmpty else {
                throw IntelligenceError.providerNotConfigured("AIProxy configuration is incomplete")
            }
        }
    }

    private func baseURL() -> URL {
        switch authentication {
        case .apiKey:
            Self.defaultBaseURL
        case let .aiProxy(_, serviceURL):
            URL(string: serviceURL) ?? Self.defaultBaseURL
        }
    }

    private func authHeaders() -> [String: String] {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "anthropic-version": Self.apiVersion
        ]

        switch authentication {
        case let .apiKey(key):
            headers["x-api-key"] = key
        case let .aiProxy(partialKey, _):
            headers["x-api-key"] = partialKey
        }

        return headers
    }

    private func buildStreamingURLRequest(for request: AnthropicMessageRequest) throws -> URLRequest {
        let url = baseURL().appendingPathComponent("v1/messages")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        for (key, value) in authHeaders() {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = try JSONEncoder().encode(request)

        return urlRequest
    }

    private func collectErrorData(from bytes: URLSession.AsyncBytes) async throws -> Data {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count > 10000 { break }
        }
        return data
    }

    private func mapHTTPError(_ error: HTTPError) -> IntelligenceError {
        switch error {
        case .invalidURL:
            .invalidRequest("Invalid API URL")
        case let .requestFailed(statusCode):
            mapHTTPStatusCode(statusCode, data: nil)
        case let .decodingFailed(underlyingError):
            .responseParseFailed(underlyingError.localizedDescription)
        case let .unknown(underlyingError):
            .requestFailed(underlyingError.localizedDescription)
        }
    }

    private func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError {
        let errorMessage = extractErrorMessage(from: data)

        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .rateLimitExceeded
        case 400:
            return .invalidRequest(errorMessage ?? "Bad request")
        case 529:
            return .requestFailed("API overloaded. Please retry later.")
        default:
            return .requestFailed(errorMessage ?? "HTTP \(statusCode)")
        }
    }

    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data)
        return errorResponse?.error.message
    }

    private func mapError(_ error: Error) -> Error {
        if error is IntelligenceError {
            return error
        }
        return IntelligenceError.requestFailed(error.localizedDescription)
    }
}

// MARK: - Endpoint

/// ARCNetworking `Endpoint` for the Anthropic Messages API.
private struct AnthropicMessagesEndpoint: Endpoint {
    typealias Response = AnthropicMessageResponse

    let resolvedBaseURL: URL
    let resolvedHeaders: [String: String]
    let request: AnthropicMessageRequest

    var baseURL: URL {
        resolvedBaseURL
    }

    var path: String {
        "v1/messages"
    }

    var method: HTTPMethod {
        .POST
    }

    var headers: [String: String]? {
        resolvedHeaders
    }

    var queryItems: [URLQueryItem]? {
        nil
    }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
