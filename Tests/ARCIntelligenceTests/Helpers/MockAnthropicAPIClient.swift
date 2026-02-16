//
//  MockAnthropicAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation
@testable import ARCIntelligence

/// Mock implementation of `AnthropicAPIClient` for testing.
///
/// Uses `NSLock` to protect mutable state, making it safe for `Sendable`
/// conformance without `@unchecked`.
final class MockAnthropicAPIClient: AnthropicAPIClient, Sendable {
    // MARK: - Thread-safe State

    private let state = MockState()

    /// Mutable mock state protected by a lock.
    private final class MockState: @unchecked Sendable {
        private let lock = NSLock()

        private var _messageResponses: [AnthropicMessageResponse] = []
        private var _streamEvents: [AnthropicStreamEvent] = []
        private var _errorToThrow: Error?
        private var _sendMessageCallCount = 0
        private var _streamMessageCallCount = 0
        private var _lastRequest: AnthropicMessageRequest?
        private var _allRequests: [AnthropicMessageRequest] = []

        var messageResponses: [AnthropicMessageResponse] {
            get { lock.withLock { _messageResponses } }
            set { lock.withLock { _messageResponses = newValue } }
        }

        var streamEvents: [AnthropicStreamEvent] {
            get { lock.withLock { _streamEvents } }
            set { lock.withLock { _streamEvents = newValue } }
        }

        var errorToThrow: Error? {
            get { lock.withLock { _errorToThrow } }
            set { lock.withLock { _errorToThrow = newValue } }
        }

        var sendMessageCallCount: Int {
            get { lock.withLock { _sendMessageCallCount } }
            set { lock.withLock { _sendMessageCallCount = newValue } }
        }

        var streamMessageCallCount: Int {
            get { lock.withLock { _streamMessageCallCount } }
            set { lock.withLock { _streamMessageCallCount = newValue } }
        }

        var lastRequest: AnthropicMessageRequest? {
            get { lock.withLock { _lastRequest } }
            set { lock.withLock { _lastRequest = newValue } }
        }

        var allRequests: [AnthropicMessageRequest] {
            get { lock.withLock { _allRequests } }
            set { lock.withLock { _allRequests = newValue } }
        }

        func removeFirstResponse() -> AnthropicMessageResponse? {
            lock.withLock {
                guard !_messageResponses.isEmpty else { return nil }
                return _messageResponses.removeFirst()
            }
        }

        func recordSendMessage(_ request: AnthropicMessageRequest) {
            lock.withLock {
                _sendMessageCallCount += 1
                _lastRequest = request
                _allRequests.append(request)
            }
        }

        func recordStreamMessage(_ request: AnthropicMessageRequest) {
            lock.withLock {
                _streamMessageCallCount += 1
                _lastRequest = request
                _allRequests.append(request)
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
