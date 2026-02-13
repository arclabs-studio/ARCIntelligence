//
//  MockAnthropicAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation
@testable import ARCIntelligence

/// Mock implementation of `AnthropicAPIClient` for testing.
final class MockAnthropicAPIClient: AnthropicAPIClient, @unchecked Sendable {
    // MARK: - Configuration

    var messageResponses: [AnthropicMessageResponse] = []
    var streamEvents: [AnthropicStreamEvent] = []
    var errorToThrow: Error?

    // MARK: - Call Tracking

    private(set) var sendMessageCallCount = 0
    private(set) var streamMessageCallCount = 0
    private(set) var lastRequest: AnthropicMessageRequest?
    private(set) var allRequests: [AnthropicMessageRequest] = []

    // MARK: - Convenience Factories

    static func withResponse(
        content: String,
        stopReason: String = "end_turn",
        inputTokens: Int = 10,
        outputTokens: Int = 20
    ) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.messageResponses = [
            AnthropicMessageResponse(
                id: "msg_test",
                type: "message",
                model: "claude-sonnet-4-5-20250929",
                content: [.text(content)],
                stopReason: stopReason,
                usage: AnthropicUsage(inputTokens: inputTokens, outputTokens: outputTokens)
            )
        ]
        return mock
    }

    static func withToolUse(
        toolId: String = "toolu_test",
        toolName: String,
        input: [String: AnyCodableValue],
        followUpText: String = "Done"
    ) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.messageResponses = [
            // First response: tool_use
            AnthropicMessageResponse(
                id: "msg_test_1",
                type: "message",
                model: "claude-sonnet-4-5-20250929",
                content: [.toolUse(id: toolId, name: toolName, input: input)],
                stopReason: "tool_use",
                usage: AnthropicUsage(inputTokens: 10, outputTokens: 20)
            ),
            // Second response: final text
            AnthropicMessageResponse(
                id: "msg_test_2",
                type: "message",
                model: "claude-sonnet-4-5-20250929",
                content: [.text(followUpText)],
                stopReason: "end_turn",
                usage: AnthropicUsage(inputTokens: 30, outputTokens: 15)
            )
        ]
        return mock
    }

    static func withError(_ error: IntelligenceError) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.errorToThrow = error
        return mock
    }

    // MARK: - AnthropicAPIClient

    func sendMessage(_ request: AnthropicMessageRequest) async throws -> AnthropicMessageResponse {
        sendMessageCallCount += 1
        lastRequest = request
        allRequests.append(request)

        if let error = errorToThrow {
            throw error
        }

        guard !messageResponses.isEmpty else {
            throw IntelligenceError.requestFailed("No mock responses configured")
        }

        // Return responses in order, removing each as it's used
        return messageResponses.removeFirst()
    }

    func streamMessage(
        _ request: AnthropicMessageRequest
    ) -> AsyncThrowingStream<AnthropicStreamEvent, Error> {
        streamMessageCallCount += 1
        lastRequest = request
        allRequests.append(request)

        if let error = errorToThrow {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        let events = streamEvents
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
