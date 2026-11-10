//
//  MockOpenAICompatibleAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation
import os
@testable import ARCIntelligence

/// Mock implementation of `OpenAICompatibleAPIClient` for testing.
///
/// Uses `OSAllocatedUnfairLock` to protect mutable state, making it safe for `Sendable`
/// conformance without `@unchecked`.
final class MockOpenAICompatibleAPIClient: OpenAICompatibleAPIClient, Sendable {
    // MARK: - Thread-safe State

    private let state = MockState()

    /// Mutable mock state protected by a lock.
    private final class MockState: Sendable {
        private let storage = OSAllocatedUnfairLock(initialState: OpenAICompatibleMockStorage())

        var chatResponses: [OpenAIChatResponse] {
            get { storage.withLock { state in state.chatResponses } }
            set { storage.withLock { state in state.chatResponses = newValue } }
        }

        var streamChunks: [OpenAIStreamChunk] {
            get { storage.withLock { state in state.streamChunks } }
            set { storage.withLock { state in state.streamChunks = newValue } }
        }

        var errorToThrow: Error? {
            get { storage.withLock { state in state.errorToThrow } }
            set { storage.withLock { state in state.errorToThrow = newValue } }
        }

        var sendCallCount: Int {
            get { storage.withLock { state in state.sendCallCount } }
            set { storage.withLock { state in state.sendCallCount = newValue } }
        }

        var streamCallCount: Int {
            get { storage.withLock { state in state.streamCallCount } }
            set { storage.withLock { state in state.streamCallCount = newValue } }
        }

        var lastRequest: OpenAIChatRequest? {
            get { storage.withLock { state in state.lastRequest } }
            set { storage.withLock { state in state.lastRequest = newValue } }
        }

        var allRequests: [OpenAIChatRequest] {
            get { storage.withLock { state in state.allRequests } }
            set { storage.withLock { state in state.allRequests = newValue } }
        }

        func removeFirstResponse() -> OpenAIChatResponse? {
            storage.withLock { state in
                guard !state.chatResponses.isEmpty else { return nil }
                return state.chatResponses.removeFirst()
            }
        }

        func recordSend(_ request: OpenAIChatRequest) {
            storage.withLock { state in
                state.sendCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
            }
        }

        func recordStream(_ request: OpenAIChatRequest) {
            storage.withLock { state in
                state.streamCallCount += 1
                state.lastRequest = request
                state.allRequests.append(request)
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
        // swiftlint:disable line_length
        mock.state.chatResponses = [OpenAIChatResponse(id: "chatcmpl-test",
                                                       object: "chat.completion",
                                                       model: "gpt-4o-mini",
                                                       choices: [OpenAIChatChoice(index: 0,
                                                                                  message: OpenAIChatChoiceMessage(role: "assistant",
                                                                                                                   content: content,
                                                                                                                   toolCalls: nil),
                                                                                  finishReason: finishReason)],
                                                       usage: OpenAIUsage(promptTokens: promptTokens,
                                                                          completionTokens: completionTokens,
                                                                          totalTokens: promptTokens +
                                                                              completionTokens))]
        // swiftlint:enable line_length
        return mock
    }

    static func withToolCall(callId: String = "call_test",
                             functionName: String,
                             arguments: String,
                             followUpText: String = "Done") -> MockOpenAICompatibleAPIClient {
        let mock = MockOpenAICompatibleAPIClient()

        let toolCall = OpenAIToolCall(id: callId,
                                      type: "function",
                                      function: OpenAIFunctionCall(name: functionName,
                                                                   arguments: arguments))
        let toolMessage = OpenAIChatChoiceMessage(role: "assistant",
                                                  content: nil,
                                                  toolCalls: [toolCall])
        let toolCallResponse = OpenAIChatResponse(id: "chatcmpl-test-1",
                                                  object: "chat.completion",
                                                  model: "gpt-4o-mini",
                                                  choices: [OpenAIChatChoice(index: 0,
                                                                             message: toolMessage,
                                                                             finishReason: "tool_calls")],
                                                  usage: OpenAIUsage(promptTokens: 10,
                                                                     completionTokens: 20,
                                                                     totalTokens: 30))

        let followUpMessage = OpenAIChatChoiceMessage(role: "assistant",
                                                      content: followUpText,
                                                      toolCalls: nil)
        let followUpResponse = OpenAIChatResponse(id: "chatcmpl-test-2",
                                                  object: "chat.completion",
                                                  model: "gpt-4o-mini",
                                                  choices: [OpenAIChatChoice(index: 0,
                                                                             message: followUpMessage,
                                                                             finishReason: "stop")],
                                                  usage: OpenAIUsage(promptTokens: 30,
                                                                     completionTokens: 15,
                                                                     totalTokens: 45))

        mock.state.chatResponses = [toolCallResponse,
                                    followUpResponse]
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

// MARK: - Storage

/// Mutable state of `MockOpenAICompatibleAPIClient`, guarded by its lock.
private struct OpenAICompatibleMockStorage {
    var chatResponses: [OpenAIChatResponse] = []
    var streamChunks: [OpenAIStreamChunk] = []
    var errorToThrow: Error?
    var sendCallCount: Int = 0
    var streamCallCount: Int = 0
    var lastRequest: OpenAIChatRequest?
    var allRequests: [OpenAIChatRequest] = []
}
