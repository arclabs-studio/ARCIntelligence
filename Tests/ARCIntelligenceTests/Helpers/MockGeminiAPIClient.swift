//
//  MockGeminiAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation
import os
@testable import ARCIntelligence

/// Mock implementation of `GeminiAPIClient` for testing.
///
/// Uses `OSAllocatedUnfairLock` to protect mutable state, making it safe for `Sendable`
/// conformance without `@unchecked`.
final class MockGeminiAPIClient: GeminiAPIClient, Sendable {
    // MARK: - Thread-safe State

    private let state = MockState()

    /// Mutable mock state protected by a lock.
    private final class MockState: Sendable {
        private let storage = OSAllocatedUnfairLock(initialState: GeminiMockStorage())

        var responses: [GeminiGenerateContentResponse] {
            get { storage.withLock { state in state.responses } }
            set { storage.withLock { state in state.responses = newValue } }
        }

        var streamChunks: [GeminiGenerateContentResponse] {
            get { storage.withLock { state in state.streamChunks } }
            set { storage.withLock { state in state.streamChunks = newValue } }
        }

        var errorToThrow: Error? {
            get { storage.withLock { state in state.errorToThrow } }
            set { storage.withLock { state in state.errorToThrow = newValue } }
        }

        var generateCallCount: Int {
            get { storage.withLock { state in state.generateCallCount } }
            set { storage.withLock { state in state.generateCallCount = newValue } }
        }

        var streamCallCount: Int {
            get { storage.withLock { state in state.streamCallCount } }
            set { storage.withLock { state in state.streamCallCount = newValue } }
        }

        var lastRequest: GeminiGenerateContentRequest? {
            get { storage.withLock { state in state.lastRequest } }
            set { storage.withLock { state in state.lastRequest = newValue } }
        }

        var allRequests: [GeminiGenerateContentRequest] {
            get { storage.withLock { state in state.allRequests } }
            set { storage.withLock { state in state.allRequests = newValue } }
        }

        func removeFirstResponse() -> GeminiGenerateContentResponse? {
            storage.withLock { state in
                guard !state.responses.isEmpty else { return nil }
                return state.responses.removeFirst()
            }
        }

        func recordGenerate(_ request: GeminiGenerateContentRequest) {
            storage.withLock { state in
                state.generateCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
            }
        }

        func recordStream(_ request: GeminiGenerateContentRequest) {
            storage.withLock { state in
                state.streamCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
            }
        }
    }

    // MARK: - Public Accessors

    var responses: [GeminiGenerateContentResponse] {
        get { state.responses }
        set { state.responses = newValue }
    }

    var streamChunks: [GeminiGenerateContentResponse] {
        get { state.streamChunks }
        set { state.streamChunks = newValue }
    }

    var errorToThrow: Error? {
        get { state.errorToThrow }
        set { state.errorToThrow = newValue }
    }

    var generateCallCount: Int {
        state.generateCallCount
    }

    var streamCallCount: Int {
        state.streamCallCount
    }

    var lastRequest: GeminiGenerateContentRequest? {
        state.lastRequest
    }

    var allRequests: [GeminiGenerateContentRequest] {
        state.allRequests
    }

    // MARK: - Convenience Factories

    static func withResponse(text: String,
                             finishReason: String = "STOP",
                             promptTokens: Int = 10,
                             outputTokens: Int = 20,
                             model: String = "gemini-2.0-flash") -> MockGeminiAPIClient {
        let mock = MockGeminiAPIClient()
        mock.state.responses = [makeResponse(text: text,
                                             finishReason: finishReason,
                                             promptTokens: promptTokens,
                                             outputTokens: outputTokens,
                                             model: model)]
        return mock
    }

    static func withFunctionCall(name: String,
                                 id: String = "call_test",
                                 args: [String: AnyCodableValue],
                                 followUpText: String = "Done") -> MockGeminiAPIClient {
        let mock = MockGeminiAPIClient()
        let functionCall = GeminiFunctionCall(name: name, id: id, args: args)
        let modelContent = GeminiContent(role: "model", parts: [.functionCall(functionCall)])
        let candidate = GeminiCandidate(content: modelContent, finishReason: "STOP")
        let usage = GeminiUsageMetadata(promptTokenCount: 10, candidatesTokenCount: 20, totalTokenCount: 30)
        let functionCallResponse = GeminiGenerateContentResponse(candidates: [candidate],
                                                                 usageMetadata: usage,
                                                                 modelVersion: "gemini-2.0-flash")
        let followUpResponse = makeResponse(text: followUpText,
                                            finishReason: "STOP",
                                            promptTokens: 30,
                                            outputTokens: 15)
        mock.state.responses = [functionCallResponse, followUpResponse]
        return mock
    }

    static func withError(_ error: IntelligenceError) -> MockGeminiAPIClient {
        let mock = MockGeminiAPIClient()
        mock.state.errorToThrow = error
        return mock
    }

    // MARK: - GeminiAPIClient

    func generateContent(_ request: GeminiGenerateContentRequest) async throws -> GeminiGenerateContentResponse {
        state.recordGenerate(request)

        if let error = state.errorToThrow {
            throw error
        }

        guard let response = state.removeFirstResponse() else {
            throw IntelligenceError.requestFailed("No mock responses configured")
        }

        return response
    }

    func streamGenerateContent(_ request: GeminiGenerateContentRequest)
    -> AsyncThrowingStream<GeminiGenerateContentResponse, Error> {
        state.recordStream(request)

        if let error = state.errorToThrow {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        let chunks = state.streamChunks
        return AsyncThrowingStream { continuation in
            Task {
                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Private Helpers

    private static func makeResponse(text: String,
                                     finishReason: String,
                                     promptTokens: Int = 10,
                                     outputTokens: Int = 20,
                                     model: String = "gemini-2.0-flash") -> GeminiGenerateContentResponse {
        GeminiGenerateContentResponse(candidates: [GeminiCandidate(content: GeminiContent(role: "model",
                                                                                          parts: [.text(text)]),
            finishReason: finishReason)],
                                      usageMetadata: GeminiUsageMetadata(promptTokenCount: promptTokens,
                                                                         candidatesTokenCount: outputTokens,
                                                                         totalTokenCount: promptTokens + outputTokens),
                                      modelVersion: model)
    }
}

// MARK: - Storage

/// Mutable state of `MockGeminiAPIClient`, guarded by its lock.
private struct GeminiMockStorage {
    var responses: [GeminiGenerateContentResponse] = []
    var streamChunks: [GeminiGenerateContentResponse] = []
    var errorToThrow: Error?
    var generateCallCount: Int = 0
    var streamCallCount: Int = 0
    var lastRequest: GeminiGenerateContentRequest?
    var allRequests: [GeminiGenerateContentRequest] = []
}
