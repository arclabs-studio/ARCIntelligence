//
//  MockAnthropicAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation
import os
@testable import ARCIntelligence

/// Mock implementation of `AnthropicAPIClient` for testing.
///
/// Uses `OSAllocatedUnfairLock` to protect mutable state, making it safe for `Sendable`
/// conformance without `@unchecked`.
final class MockAnthropicAPIClient: AnthropicAPIClient, Sendable {
    // MARK: - Thread-safe State

    private let state = MockState()

    /// Mutable mock state protected by a lock.
    private final class MockState: Sendable {
        private let storage = OSAllocatedUnfairLock(initialState: AnthropicMockStorage())

        var messageResponses: [AnthropicMessageResponse] {
            get { storage.withLock { state in state.messageResponses } }
            set { storage.withLock { state in state.messageResponses = newValue } }
        }

        var streamEvents: [AnthropicStreamEvent] {
            get { storage.withLock { state in state.streamEvents } }
            set { storage.withLock { state in state.streamEvents = newValue } }
        }

        var errorToThrow: Error? {
            get { storage.withLock { state in state.errorToThrow } }
            set { storage.withLock { state in state.errorToThrow = newValue } }
        }

        var sendMessageCallCount: Int {
            get { storage.withLock { state in state.sendMessageCallCount } }
            set { storage.withLock { state in state.sendMessageCallCount = newValue } }
        }

        var streamMessageCallCount: Int {
            get { storage.withLock { state in state.streamMessageCallCount } }
            set { storage.withLock { state in state.streamMessageCallCount = newValue } }
        }

        var lastRequest: AnthropicMessageRequest? {
            get { storage.withLock { state in state.lastRequest } }
            set { storage.withLock { state in state.lastRequest = newValue } }
        }

        var allRequests: [AnthropicMessageRequest] {
            get { storage.withLock { state in state.allRequests } }
            set { storage.withLock { state in state.allRequests = newValue } }
        }

        func removeFirstResponse() -> AnthropicMessageResponse? {
            storage.withLock { state in
                guard !state.messageResponses.isEmpty else { return nil }
                return state.messageResponses.removeFirst()
            }
        }

        func recordSendMessage(_ request: AnthropicMessageRequest) {
            storage.withLock { state in
                state.sendMessageCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
            }
        }

        func recordStreamMessage(_ request: AnthropicMessageRequest) {
            storage.withLock { state in
                state.streamMessageCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
            }
        }
    }

    // MARK: - Public Accessors

    var messageResponses: [AnthropicMessageResponse] {
        get { state.messageResponses }
        set { state.messageResponses = newValue }
    }

    var streamEvents: [AnthropicStreamEvent] {
        get { state.streamEvents }
        set { state.streamEvents = newValue }
    }

    var errorToThrow: Error? {
        get { state.errorToThrow }
        set { state.errorToThrow = newValue }
    }

    var sendMessageCallCount: Int {
        state.sendMessageCallCount
    }

    var streamMessageCallCount: Int {
        state.streamMessageCallCount
    }

    var lastRequest: AnthropicMessageRequest? {
        state.lastRequest
    }

    var allRequests: [AnthropicMessageRequest] {
        state.allRequests
    }

    // MARK: - Convenience Factories

    static func withResponse(content: String,
                             stopReason: String = "end_turn",
                             inputTokens: Int = 10,
                             outputTokens: Int = 20) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.state.messageResponses = [AnthropicMessageResponse(id: "msg_test",
                                                                type: "message",
                                                                model: "claude-sonnet-4-5-20250929",
                                                                content: [.text(content)],
                                                                stopReason: stopReason,
                                                                usage: AnthropicUsage(inputTokens: inputTokens,
                                                                                      outputTokens: outputTokens))]
        return mock
    }

    static func withToolUse(toolId: String = "toolu_test",
                            toolName: String,
                            input: [String: AnyCodableValue],
                            followUpText: String = "Done") -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        let toolUseResponse = AnthropicMessageResponse(id: "msg_test_1",
                                                       type: "message",
                                                       model: "claude-sonnet-4-5-20250929",
                                                       content: [.toolUse(id: toolId, name: toolName, input: input)],
                                                       stopReason: "tool_use",
                                                       usage: AnthropicUsage(inputTokens: 10, outputTokens: 20))
        let followUpResponse = AnthropicMessageResponse(id: "msg_test_2",
                                                        type: "message",
                                                        model: "claude-sonnet-4-5-20250929",
                                                        content: [.text(followUpText)],
                                                        stopReason: "end_turn",
                                                        usage: AnthropicUsage(inputTokens: 30, outputTokens: 15))
        mock.state.messageResponses = [toolUseResponse, followUpResponse]
        return mock
    }

    static func withError(_ error: IntelligenceError) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.state.errorToThrow = error
        return mock
    }

    // MARK: - AnthropicAPIClient

    func sendMessage(_ request: AnthropicMessageRequest) async throws -> AnthropicMessageResponse {
        state.recordSendMessage(request)

        if let error = state.errorToThrow {
            throw error
        }

        guard let response = state.removeFirstResponse() else {
            throw IntelligenceError.requestFailed("No mock responses configured")
        }

        return response
    }

    func streamMessage(_ request: AnthropicMessageRequest) -> AsyncThrowingStream<AnthropicStreamEvent, Error> {
        state.recordStreamMessage(request)

        if let error = state.errorToThrow {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        let events = state.streamEvents
        return AsyncThrowingStream { continuation in
            Task {
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Storage

/// Mutable state of `MockAnthropicAPIClient`, guarded by its lock.
private struct AnthropicMockStorage {
    var messageResponses: [AnthropicMessageResponse] = []
    var streamEvents: [AnthropicStreamEvent] = []
    var errorToThrow: Error?
    var sendMessageCallCount: Int = 0
    var streamMessageCallCount: Int = 0
    var lastRequest: AnthropicMessageRequest?
    var allRequests: [AnthropicMessageRequest] = []
}
