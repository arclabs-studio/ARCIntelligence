//
//  MockConversationProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `ConversationProvider` for testing conversational features.
///
/// Provides a simple echo-style conversation for testing purposes.
public final class MockConversationProvider: ConversationProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.conversation"
    public let displayName = "Mock Conversation Provider"
    public let version = "1.0"

    private let responsePrefix: String

    // MARK: - Initialization

    public init(responsePrefix: String = "Echo: ") {
        self.responsePrefix = responsePrefix
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        let response = responsePrefix + prompt
        return IntelligenceResponse(content: response,
                                    tokensUsed: response.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let response = responsePrefix + prompt
                for char in response {
                    try await Task.sleep(for: .milliseconds(10))
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - ConversationProvider

    public func sendMessage(_ message: Message,
                            in conversation: Conversation) async throws -> Message {
        let response = try await complete(prompt: message.content,
                                          configuration: .default)

        return Message(role: .assistant,
                       content: response.content,
                       metadata: ["conversationId": conversation.id.uuidString])
    }

    public func continueConversation(_ conversation: Conversation,
                                     with text: String) async throws -> Message {
        let userMessage = Message(role: .user, content: text)
        return try await sendMessage(userMessage, in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        conversation.messages.reduce(0) { $0 + $1.content.count / 4 }
    }
}
