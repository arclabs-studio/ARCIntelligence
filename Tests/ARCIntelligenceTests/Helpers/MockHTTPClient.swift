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
final class MockHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    // MARK: - State

    var responseToReturn: Any?
    var errorToThrow: Error?
    var lastExecutedEndpoint: (any Endpoint)?

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
}
