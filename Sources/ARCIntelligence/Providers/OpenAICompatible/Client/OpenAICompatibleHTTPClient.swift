//
//  OpenAICompatibleHTTPClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import ARCLogger
import ARCNetworking
import Foundation

/// Concrete implementation of `OpenAICompatibleAPIClient` using ARCNetworking for
/// standard requests and URLSession for streaming SSE.
///
/// Used by both OpenAI and Grok providers with different base URLs and auth headers.
final class OpenAICompatibleHTTPClient: OpenAICompatibleAPIClient, StreamingHTTPClientSupport, Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private let authHeaders: [String: String]
    private let httpClient: HTTPClientProtocol
    private let session: URLSession
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "OpenAICompatibleHTTP")

    // MARK: - Initialization

    init(baseURL: URL,
         authHeaders: [String: String],
         httpClient: HTTPClientProtocol = HTTPClient(),
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.authHeaders = authHeaders
        self.httpClient = httpClient
        self.session = session
    }

    // MARK: - OpenAICompatibleAPIClient

    func sendChatCompletion(_ request: OpenAIChatRequest) async throws -> OpenAIChatResponse {
        try validateAuthHeaders()

        let endpoint = ChatCompletionsEndpoint(resolvedBaseURL: baseURL,
                                               resolvedHeaders: authHeaders,
                                               request: request)

        do {
            return try await httpClient.execute(endpoint)
        } catch let httpError as HTTPError {
            throw mapHTTPError(httpError)
        }
    }

    func streamChatCompletion(_ request: OpenAIChatRequest) -> AsyncThrowingStream<OpenAIStreamChunk, Error> {
        let client = self
        return AsyncThrowingStream { continuation in
            let task = Task.detached {
                do {
                    try client.validateAuthHeaders()

                    let urlRequest = try client.buildStreamingURLRequest(for: request)
                    let (bytes, response) = try await client.session.bytes(for: urlRequest)

                    if let httpResponse = response as? HTTPURLResponse {
                        let isError = !(200 ... 299).contains(httpResponse.statusCode)
                        if isError {
                            let errorData = try await client.collectErrorData(from: bytes)
                            let error = client.mapHTTPStatusCode(httpResponse.statusCode, data: errorData)
                            continuation.finish(throwing: error)
                            return
                        }
                    }

                    let parser = OpenAICompatibleStreamParser()
                    let chunkStream = parser.parse(bytes)

                    for try await chunk in chunkStream {
                        continuation.yield(chunk)

                        if let choice = chunk.choices?.first, choice.finishReason != nil {
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

    private func validateAuthHeaders() throws {
        guard !authHeaders.isEmpty else {
            throw IntelligenceError.providerNotConfigured("Authentication headers are empty")
        }

        let hasAuth = authHeaders.keys.contains(where: { $0.lowercased() == "authorization" })
        guard hasAuth else {
            throw IntelligenceError.providerNotConfigured("Missing Authorization header")
        }
    }

    private func buildStreamingURLRequest(for request: OpenAIChatRequest) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("v1/chat/completions")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        for (key, value) in authHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = try JSONEncoder().encode(request)

        return urlRequest
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
        case 500 ... 599:
            return .requestFailed(errorMessage ?? "Server error (HTTP \(statusCode))")
        default:
            return .requestFailed(errorMessage ?? "HTTP \(statusCode)")
        }
    }

    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
        return errorResponse?.error.message
    }
}

// MARK: - Endpoint

/// ARCNetworking `Endpoint` for the OpenAI Chat Completions API.
private struct ChatCompletionsEndpoint: Endpoint {
    typealias Response = OpenAIChatResponse

    let resolvedBaseURL: URL
    let resolvedHeaders: [String: String]
    let request: OpenAIChatRequest

    var baseURL: URL {
        resolvedBaseURL
    }

    var path: String {
        "v1/chat/completions"
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
