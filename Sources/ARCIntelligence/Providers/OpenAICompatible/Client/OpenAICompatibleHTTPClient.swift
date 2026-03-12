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
/// all requests including SSE streaming.
///
/// Used by both OpenAI and Grok providers with different base URLs and auth headers.
final class OpenAICompatibleHTTPClient: OpenAICompatibleAPIClient, StreamingHTTPClientSupport, Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private let authHeaders: [String: String]
    private let httpClient: HTTPClientProtocol
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "OpenAICompatibleHTTP")

    // MARK: - Initialization

    init(baseURL: URL,
         authHeaders: [String: String],
         httpClient: HTTPClientProtocol = HTTPClient()) {
        self.baseURL = baseURL
        self.authHeaders = authHeaders
        self.httpClient = httpClient
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

                    let endpoint = ChatCompletionsEndpoint(resolvedBaseURL: client.baseURL,
                                                           resolvedHeaders: client.authHeaders,
                                                           request: request)
                    let parser = OpenAICompatibleStreamParser()
                    let chunkStream = parser.parse(client.httpClient.stream(endpoint))

                    for try await chunk in chunkStream {
                        continuation.yield(chunk)

                        if let choice = chunk.choices?.first, choice.finishReason != nil {
                            continuation.finish()
                            return
                        }
                    }

                    continuation.finish()
                } catch let httpError as HTTPError {
                    continuation.finish(throwing: client.mapHTTPError(httpError))
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
}

// MARK: - StreamingHTTPClientSupport (OpenAI-specific overrides)

extension OpenAICompatibleHTTPClient {
    /// OpenAI-compatible APIs treat the entire 5xx range as server errors.
    func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError {
        let errorMessage = extractErrorMessage(from: data)
        switch statusCode {
        case HTTPStatusCode.unauthorized:
            return .authenticationFailed
        case HTTPStatusCode.badRequest:
            return .invalidRequest(errorMessage ?? "Bad request")
        case 429:
            return .rateLimitExceeded
        case HTTPStatusCode.internalServerError ... HTTPStatusCode.serviceUnavailable:
            return .requestFailed(errorMessage ?? "Server error (HTTP \(statusCode))")
        default:
            return .requestFailed(errorMessage ?? "HTTP \(statusCode)")
        }
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
