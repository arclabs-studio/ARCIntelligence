//
//  StreamingHTTPClientSupport.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

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
}
