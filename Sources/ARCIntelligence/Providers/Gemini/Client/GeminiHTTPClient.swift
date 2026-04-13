//
//  GeminiHTTPClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import ARCLogger
import ARCNetworking
import Foundation

/// Concrete implementation of `GeminiAPIClient` using ARCNetworking for
/// all requests including SSE streaming.
///
/// Uses the stable `v1` Gemini REST API at `generativelanguage.googleapis.com`.
final class GeminiHTTPClient: GeminiAPIClient, StreamingHTTPClientSupport, Sendable {
    // MARK: - Properties

    private let authentication: GeminiAuthentication
    private let httpClient: HTTPClientProtocol
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "GeminiHTTP")

    // MARK: - Constants

    private static let defaultBaseURL = URL(literal: "https://generativelanguage.googleapis.com")

    // MARK: - Initialization

    /// Creates a Gemini HTTP client.
    ///
    /// - Parameters:
    ///   - authentication: The authentication strategy (API key or AIProxy).
    ///   - httpClient: The underlying HTTP client. Defaults to an `HTTPClient` with
    ///     `RetryInterceptor(maxRetries: 2)` followed by `LoggingInterceptor`, providing
    ///     exponential-backoff retry on transient 5xx errors out of the box.
    ///     Inject a `MockHTTPClient` in tests to avoid network access.
    init(authentication: GeminiAuthentication,
         httpClient: HTTPClientProtocol = HTTPClient(interceptors: [RetryInterceptor(maxRetries: 2),
                                                                    LoggingInterceptor()])) {
        self.authentication = authentication
        self.httpClient = httpClient
    }

    // MARK: - GeminiAPIClient

    func generateContent(_ request: GeminiGenerateContentRequest) async throws -> GeminiGenerateContentResponse {
        try validateAuthentication()

        let endpoint = GeminiGenerateContentEndpoint(resolvedBaseURL: baseURL(),
                                                     resolvedHeaders: authHeaders(),
                                                     request: request)

        do {
            return try await httpClient.execute(endpoint)
        } catch let httpError as HTTPError {
            throw mapHTTPError(httpError)
        }
    }

    func streamGenerateContent(_ request: GeminiGenerateContentRequest)
    -> AsyncThrowingStream<GeminiGenerateContentResponse, Error> {
        let client = self
        return AsyncThrowingStream { continuation in
            let task = Task.detached {
                do {
                    try client.validateAuthentication()

                    let endpoint = GeminiStreamGenerateContentEndpoint(resolvedBaseURL: client.baseURL(),
                                                                       resolvedHeaders: client.authHeaders(),
                                                                       request: request)
                    let parser = GeminiStreamParser()
                    let chunkStream = parser.parse(client.httpClient.stream(endpoint))

                    for try await chunk in chunkStream {
                        continuation.yield(chunk)

                        if let finishReason = chunk.candidates?.first?.finishReason,
                           !finishReason.isEmpty {
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

    private func validateAuthentication() throws {
        switch authentication {
        case let .apiKey(key):
            guard !key.isEmpty else {
                throw IntelligenceError.providerNotConfigured("Gemini API key is empty")
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
        var headers = ["Content-Type": "application/json"]

        switch authentication {
        case let .apiKey(key):
            headers["x-goog-api-key"] = key
        case let .aiProxy(partialKey, _):
            headers["x-goog-api-key"] = partialKey
        }

        return headers
    }
}

// MARK: - StreamingHTTPClientSupport (Gemini-specific overrides)

extension GeminiHTTPClient {
    /// Gemini uses standard HTTP status codes with a 503 for model overload.
    func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError {
        if statusCode == 503 {
            return .requestFailed("Model overloaded. Please retry later.")
        }
        let errorMessage = extractGeminiErrorMessage(from: data)
        switch statusCode {
        case HTTPStatusCode.unauthorized, HTTPStatusCode.forbidden:
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

    /// Gemini wraps errors in `{"error": {"message": "..."}}` — same envelope as
    /// the default `StreamingHTTPClientSupport.extractErrorMessage(from:)`.
    private func extractGeminiErrorMessage(from data: Data?) -> String? {
        extractErrorMessage(from: data)
    }
}

// MARK: - Endpoints

/// ARCNetworking `Endpoint` for `POST /v1/models/{model}:generateContent`.
private struct GeminiGenerateContentEndpoint: Endpoint {
    typealias Response = GeminiGenerateContentResponse

    let resolvedBaseURL: URL
    let resolvedHeaders: [String: String]
    let request: GeminiGenerateContentRequest

    var baseURL: URL {
        resolvedBaseURL
    }

    var path: String {
        "v1/models/\(request.model):generateContent"
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

/// ARCNetworking `Endpoint` for `POST /v1/models/{model}:streamGenerateContent?alt=sse`.
private struct GeminiStreamGenerateContentEndpoint: Endpoint {
    typealias Response = GeminiGenerateContentResponse

    let resolvedBaseURL: URL
    let resolvedHeaders: [String: String]
    let request: GeminiGenerateContentRequest

    var baseURL: URL {
        resolvedBaseURL
    }

    var path: String {
        "v1/models/\(request.model):streamGenerateContent"
    }

    var method: HTTPMethod {
        .POST
    }

    var headers: [String: String]? {
        resolvedHeaders
    }

    var queryItems: [URLQueryItem]? {
        [URLQueryItem(name: "alt", value: "sse")]
    }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
