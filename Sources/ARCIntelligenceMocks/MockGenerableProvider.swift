//
//  MockGenerableProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `GenerableProvider` for testing.
///
/// Allows configuring canned responses for guided generation testing.
/// Supports custom response generators for type-specific mocking.
///
/// ## Usage
/// ```swift
/// // Simple usage with JSON response
/// let mock = MockGenerableProvider(
///     jsonResponse: #"{"name": "Test", "value": 42}"#
/// )
///
/// // With custom generator
/// let mock = MockGenerableProvider { type, prompt in
///     if type == MyType.self {
///         return MyType(name: "Generated")
///     }
///     throw IntelligenceError.invalidRequest("Unknown type")
/// }
/// ```
public final class MockGenerableProvider: IntelligenceProvider, GenerableProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.generable"
    public let displayName = "Mock Generable Provider"
    public let version = "1.0"

    private let jsonResponse: String?
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval
    private let errorToThrow: IntelligenceError?

    // MARK: - Initialization

    /// Create a mock provider with a JSON response string.
    ///
    /// - Parameters:
    ///   - jsonResponse: JSON string to decode as the response.
    ///   - shouldFail: Whether to simulate failure.
    ///   - simulatedDelay: Delay before returning response.
    ///   - errorToThrow: Specific error to throw when failing.
    public init(jsonResponse: String? = nil,
                shouldFail: Bool = false,
                simulatedDelay: TimeInterval = 0.1,
                errorToThrow: IntelligenceError? = nil) {
        self.jsonResponse = jsonResponse
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
        self.errorToThrow = errorToThrow
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt _: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock failure")
        }

        let response = jsonResponse ?? "{}"
        return IntelligenceResponse(content: response,
                                    tokensUsed: response.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt _: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: errorToThrow ?? IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                let response = jsonResponse ?? "{}"
                continuation.yield(response)
                continuation.finish()
            }
        }
    }

    // MARK: - GenerableProvider

    public func generate<T: Codable & Sendable>(_ type: T.Type,
                                                prompt _: String,
                                                configuration _: CompletionConfiguration) async throws -> T {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock generation failure")
        }

        guard let json = jsonResponse else {
            throw IntelligenceError.responseParseFailed("No JSON response configured")
        }

        guard let data = json.data(using: .utf8) else {
            throw IntelligenceError.responseParseFailed("Invalid JSON encoding")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw IntelligenceError.responseParseFailed("Failed to decode \(type): \(error.localizedDescription)")
        }
    }
}
