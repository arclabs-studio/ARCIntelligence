//
//  StreamingHTTPClientSupport.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import ARCNetworking
import Foundation

/// Shared helpers for HTTP clients that handle SSE streaming via ARCNetworking.
///
/// Both `AnthropicHTTPClient` and `OpenAICompatibleHTTPClient` implement the same
/// logic for normalising errors into `IntelligenceError`. This protocol provides
/// those default implementations so concrete clients only need to declare conformance.
protocol StreamingHTTPClientSupport {
    /// Normalise an arbitrary error into an `IntelligenceError`.
    ///
    /// If the error is already an `IntelligenceError` it is returned as-is;
    /// otherwise it is wrapped in `.requestFailed`.
    func mapError(_ error: Error) -> Error

    /// Map an `HTTPError` from ARCNetworking into an `IntelligenceError`.
    func mapHTTPError(_ error: HTTPError) -> IntelligenceError

    /// Extract a human-readable error message from raw response data.
    func extractErrorMessage(from data: Data?) -> String?

    /// Map an HTTP status code (and optional error body) to an `IntelligenceError`.
    ///
    /// Conformers may override this to handle provider-specific status codes
    /// (e.g. Anthropic's 529 overload code).
    func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError
}

// MARK: - Default Implementations

extension StreamingHTTPClientSupport {
    func mapError(_ error: Error) -> Error {
        if error is IntelligenceError {
            return error
        }
        return IntelligenceError.requestFailed(error.localizedDescription)
    }

    func mapHTTPError(_ error: HTTPError) -> IntelligenceError {
        switch error {
        case .invalidURL:
            .invalidRequest("Invalid API URL")
        case let .requestFailed(statusCode, data):
            mapHTTPStatusCode(statusCode, data: data)
        case let .decodingFailed(underlyingError):
            .responseParseFailed(underlyingError.localizedDescription)
        case let .unknown(underlyingError):
            .requestFailed(underlyingError.localizedDescription)
        }
    }

    func extractErrorMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        return (try? JSONDecoder().decode(StreamingErrorEnvelope.self, from: data))?.error.message
    }
}

// MARK: - Private Types

private struct StreamingErrorEnvelope: Decodable {
    struct ErrorBody: Decodable {
        let message: String
    }

    let error: ErrorBody
}

// MARK: - Default Status Code Mapping

extension StreamingHTTPClientSupport {
    func mapHTTPStatusCode(_ statusCode: Int, data: Data?) -> IntelligenceError {
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
