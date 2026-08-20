//
//  MockHTTPClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/03/2026.
//

import ARCNetworking
import Foundation
@testable import ARCIntelligence

/// Mock `HTTPClientProtocol` for testing HTTP clients without network access.
///
/// Stores a single response (as `Any`) and/or an error. The generic `execute`
/// casts the stored response to `T.Response` — configure it to match the
/// endpoint you are testing.
///
/// For streaming tests, set `streamLinesToReturn` to a sequence of raw SSE
/// `Data` lines to yield, or `streamErrorToThrow` to have the stream fail
/// immediately with that error.
final class MockHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    // MARK: - State

    var responseToReturn: Any?
    var errorToThrow: Error?
    var lastExecutedEndpoint: (any Endpoint)?

    /// SSE lines to yield from `stream(_:)`. Each element is one raw line (e.g. `"data: {...}"` as UTF-8 `Data`).
    var streamLinesToReturn: [Data]?
    /// Error to throw immediately from `stream(_:)`.
    var streamErrorToThrow: Error?

    // MARK: - HTTPClientProtocol

    func execute<T: Endpoint>(_ endpoint: T) async throws -> T.Response {
        lastExecutedEndpoint = endpoint

        if let error = errorToThrow {
            throw error
        }

        guard let response = responseToReturn as? T.Response else {
            throw HTTPError.unknown(NSError(domain: "MockHTTPClient",
                                            code: 0,
                                            userInfo: [NSLocalizedDescriptionKey: "No response configured"]))
        }

        return response
    }

    func stream(_: some Endpoint) -> AsyncThrowingStream<Data, Error> {
        if let error = streamErrorToThrow {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
        let lines = streamLinesToReturn ?? []
        return AsyncThrowingStream { continuation in
            for line in lines {
                continuation.yield(line)
            }
            continuation.finish()
        }
    }
}
