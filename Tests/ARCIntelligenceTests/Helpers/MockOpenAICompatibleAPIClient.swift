//
//  MockOpenAICompatibleAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation
@testable import ARCIntelligence

/// Mock implementation of `OpenAICompatibleAPIClient` for testing.
///
/// Uses `NSLock` to protect mutable state, making it safe for `Sendable`
/// conformance without `@unchecked`.
final class MockOpenAICompatibleAPIClient: OpenAICompatibleAPIClient, Sendable {
    // MARK: - Thread-safe State

    private let state = MockState()

    /// Mutable mock state protected by a lock.
    private final class MockState: @unchecked Sendable {
        private let lock = NSLock()

        private var _chatResponses: [OpenAIChatResponse] = []
        private var _streamChunks: [OpenAIStreamChunk] = []
        private var _errorToThrow: Error?
        private var _sendCallCount = 0
        private var _streamCallCount = 0
        private var _lastRequest: OpenAIChatRequest?
        private var _allRequests: [OpenAIChatRequest] = []

        var chatResponses: [OpenAIChatResponse] {
            get { lock.withLock { _chatResponses } }
            set { lock.withLock { _chatResponses = newValue } }
        }

        var streamChunks: [OpenAIStreamChunk] {
            get { lock.withLock { _streamChunks } }
            set { lock.withLock { _streamChunks = newValue } }
        }

        var errorToThrow: Error? {
            get { lock.withLock { _errorToThrow } }
            set { lock.withLock { _errorToThrow = newValue } }
        }

        var sendCallCount: Int {
            get { lock.withLock { _sendCallCount } }
            set { lock.withLock { _sendCallCount = newValue } }
        }

        var streamCallCount: Int {
            get { lock.withLock { _streamCallCount } }
            set { lock.withLock { _streamCallCount = newValue } }
        }

        var lastRequest: OpenAIChatRequest? {
            get { lock.withLock { _lastRequest } }
            set { lock.withLock { _lastRequest = newValue } }
        }

        var allRequests: [OpenAIChatRequest] {
            get { lock.withLock { _allRequests } }
            set { lock.withLock { _allRequests = newValue } }
        }

        func removeFirstResponse() -> OpenAIChatResponse? {
            lock.withLock {
                guard !_chatResponses.isEmpty else { return nil }
                return _chatResponses.removeFirst()
            }
        }

        func recordSend(_ request: OpenAIChatRequest) {
            lock.withLock {
                _sendCallCount += 1
                _lastRequest = request
                _allRequests.append(request)
            }
        }

        func recordStream(_ request: OpenAIChatRequest) {
            lock.withLock {
                _streamCallCount += 1
                _lastRequest = request
                _allRequests.append(request)
            }
        }
    }

    // MARK: - Public Accessors

    var chatResponses: [OpenAIChatResponse] {
        get { state.chatResponses }
        set { state.chatResponses = newValue }
    }

    var streamChunks: [OpenAIStreamChunk] {
        get { state.streamChunks }
        set { state.streamChunks = newValue }
    }

    var errorToThrow: Error? {
        get { state.errorToThrow }
        set { state.errorToThrow = newValue }
    }

    var sendCallCount: Int {
        state.sendCallCount
    }

    var streamCallCount: Int {
        state.streamCallCount
    }

    var lastRequest: OpenAIChatRequest? {
        state.lastRequest
    }

    var allRequests: [OpenAIChatRequest] {
        state.allRequests
    }

    // MARK: - Convenience Factories

    static func withResponse(content: String,
                             finishReason: String = "stop",
                             promptTokens: Int = 10,
                             completionTokens: Int = 20) -> MockOpenAICompatibleAPIClient {
        let mock = MockOpenAICompatibleAPIClient()
        mock.state.chatResponses = [
            OpenAIChatResponse(
                id: "chatcmpl-test",
                object: "chat.completion",
                model: "gpt-4o-mini",
                choices: [
                    OpenAIChatChoice(
                        index: 0,
                        message: OpenAIChatChoiceMessage(role: "assistant",
                                                         content: content,
                                                         toolCalls: nil),
                        finishReason: finishReason
                    )
                ],
                usage: OpenAIUsage(promptTokens: promptTokens,
                                   completionTokens: completionTokens,
                                   totalTokens: promptTokens + completionTokens)
            )
        ]
        return mock
    }

    static func withToolCall(callId: String = "call_test",
                             functionName: String,
                             arguments: String,
                             followUpText: String = "Done") -> MockOpenAICompatibleAPIClient {
        let mock = MockOpenAICompatibleAPIClient()
        let toolCallResponse = OpenAIChatResponse(
            id: "chatcmpl-test-1",
            object: "chat.completion",
            model: "gpt-4o-mini",
            choices: [
                OpenAIChatChoice(
                    index: 0,
                    message: OpenAIChatChoiceMessage(
                        role: "assistant",
                        content: nil,
                        toolCalls: [
                            OpenAIToolCall(id: callId,
                                           type: "function",
                                           function: OpenAIFunctionCall(name: functionName,
                                                                        arguments: arguments))
                        ]
                    ),
                    finishReason: "tool_calls"
                )
            ],
            usage: OpenAIUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)
        )
        let followUpResponse = OpenAIChatResponse(
            id: "chatcmpl-test-2",
            object: "chat.completion",
            model: "gpt-4o-mini",
            choices: [
                OpenAIChatChoice(
                    index: 0,
                    message: OpenAIChatChoiceMessage(role: "assistant",
                                                     content: followUpText,
                                                     toolCalls: nil),
                    finishReason: "stop"
                )
            ],
            usage: OpenAIUsage(promptTokens: 30, completionTokens: 15, totalTokens: 45)
        )
        mock.state.chatResponses = [toolCallResponse, followUpResponse]
        return mock
    }

    static func withError(_ error: IntelligenceError) -> MockOpenAICompatibleAPIClient {
        let mock = MockOpenAICompatibleAPIClient()
        mock.state.errorToThrow = error
        return mock
    }

    // MARK: - OpenAICompatibleAPIClient

    func sendChatCompletion(_ request: OpenAIChatRequest) async throws -> OpenAIChatResponse {
        state.recordSend(request)

        if let error = state.errorToThrow {
            throw error
        }

        guard let response = state.removeFirstResponse() else {
            throw IntelligenceError.requestFailed("No mock responses configured")
        }

        return response
    }

    func streamChatCompletion(_ request: OpenAIChatRequest) -> AsyncThrowingStream<OpenAIStreamChunk, Error> {
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
}
