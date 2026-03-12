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
final class AnthropicHTTPClient: AnthropicAPIClient, StreamingHTTPClientSupport, Sendable {
    // MARK: - Properties

    private let authentication: AnthropicAuthentication
    private let httpClient: HTTPClientProtocol
    private let session: URLSession
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "AnthropicHTTP")

    // MARK: - Constants

    private static let apiVersion = "2023-06-01"
    private static let defaultBaseURL = URL(literal: "https://api.anthropic.com")

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
        let client = self
        return AsyncThrowingStream { continuation in
            let task = Task.detached {
                do {
                    try client.validateAuthentication()

                    let urlRequest = try client.buildStreamingURLRequest(for: request)
                    let (bytes, response) = try await client.session.bytes(for: urlRequest)

                    if let httpResponse = response as? HTTPURLResponse,
                       !HTTPStatusCode.successRange.contains(httpResponse.statusCode) {
                        let errorData = try await client.collectErrorData(from: bytes)
                        let error = client.mapHTTPStatusCode(httpResponse.statusCode, data: errorData)
                        continuation.finish(throwing: error)
                        return
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
                    client.logger.error("Streaming failed",
                                        metadata: ["error": .public(error.localizedDescription)])
                    continuation.finish(throwing: client.mapError(error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
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
        var headers: [String: String] = ["Content-Type": "application/json",
                                         "anthropic-version": Self.apiVersion]

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
}

// MARK: - StreamingHTTPClientSupport (Anthropic-specific overrides)

extension AnthropicHTTPClient {
    /// Anthropic adds a provider-specific 529 "overloaded" status code.
    func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError {
        if statusCode == 529 {
            return .requestFailed("API overloaded. Please retry later.")
        }
        let errorMessage = extractErrorMessage(from: data)
        switch statusCode {
        case HTTPStatusCode.unauthorized:
            return .authenticationFailed
        case HTTPStatusCode.badRequest:
            return .invalidRequest(errorMessage ?? "Bad request")
        case 429:
            return .rateLimitExceeded
        default:
            return .requestFailed(errorMessage ?? "HTTP \(statusCode)")
        }
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
