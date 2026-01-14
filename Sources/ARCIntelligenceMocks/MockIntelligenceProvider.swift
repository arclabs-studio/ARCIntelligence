//
//  MockIntelligenceProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `IntelligenceProvider` for testing.
///
/// Allows configuring canned responses and simulating various scenarios
/// including errors, delays, and streaming behavior.
public final class MockIntelligenceProvider: IntelligenceProvider, ConversationProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock"
    public let displayName = "Mock Provider"
    public let version = "1.0"

    private let responses: [String]
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval

    // MARK: - Initialization

    public init(
        responses: [String] = ["Mock response"],
        shouldFail: Bool = false,
        simulatedDelay: TimeInterval = 0.1
    ) {
        self.responses = responses
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(
        prompt _: String,
        configuration _: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw IntelligenceError.requestFailed("Mock failure")
        }

        let response = responses.randomElement() ?? "Default mock response"
        return IntelligenceResponse(
            content: response,
            tokensUsed: response.count / 4,
            finishReason: .completed
        )
    }

    public func streamComplete(
        prompt _: String,
        configuration _: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                let response = responses.randomElement() ?? "Default mock response"
                for char in response {
                    try await Task.sleep(for: .milliseconds(10))
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - ConversationProvider

    public func sendMessage(
        _ message: Message,
        in _: Conversation
    ) async throws -> Message {
        let response = try await complete(
            prompt: message.content,
            configuration: .default
        )

        return Message(
            role: .assistant,
            content: response.content
        )
    }

    public func continueConversation(
        _ conversation: Conversation,
        with text: String
    ) async throws -> Message {
        let userMessage = Message(role: .user, content: text)
        return try await sendMessage(userMessage, in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        conversation.messages.reduce(0) { $0 + $1.content.count / 4 }
    }
}
