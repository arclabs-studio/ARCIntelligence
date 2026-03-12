//
//  StreamingHTTPClientSupport.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import ARCNetworking
import Foundation

/// Shared helpers for HTTP clients that handle SSE streaming via URLSession.
///
/// Both `AnthropicHTTPClient` and `OpenAICompatibleHTTPClient` implement the same
/// logic for collecting error response bodies and normalising thrown errors into
/// `IntelligenceError`. This protocol provides those default implementations so
/// concrete clients only need to declare conformance.
protocol StreamingHTTPClientSupport {
    /// Read raw bytes from a streaming response into a `Data` buffer.
    ///
    /// Stops after 10 KB to avoid consuming large bodies on error paths.
    func collectErrorData(from bytes: URLSession.AsyncBytes) async throws -> Data

    /// Normalise an arbitrary error into an `IntelligenceError`.
    ///
    /// If the error is already an `IntelligenceError` it is returned as-is;
    /// otherwise it is wrapped in `.requestFailed`.
    func mapError(_ error: Error) -> Error

    /// Map an `HTTPError` from ARCNetworking into an `IntelligenceError`.
    func mapHTTPError(_ error: HTTPError) -> IntelligenceError

    /// Extract a human-readable error message from raw response data.
    func extractErrorMessage(from data: Data?) -> String?
}

// MARK: - Default Implementations

extension StreamingHTTPClientSupport {
    func collectErrorData(from bytes: URLSession.AsyncBytes) async throws -> Data {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count > 10000 { break }
        }
        return data
    }

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
        case let .requestFailed(statusCode):
            mapHTTPStatusCode(statusCode, data: nil)
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

// MARK: - Private Helpers

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
