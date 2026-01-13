//
//  ConversationalAssistant.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Actor for managing conversational AI interactions.
///
/// Maintains conversation state and handles multi-turn dialogues with an AI assistant.
/// Thread-safe through actor isolation.
public actor ConversationalAssistant {

    // MARK: - Properties

    private let provider: ConversationProvider
    private var activeConversation: Conversation?

    // MARK: - Initialization

    public init(provider: ConversationProvider) {
        self.provider = provider
    }

    // MARK: - Public Methods

    /// Start a new conversation with optional system prompt
    /// - Parameter systemPrompt: Instructions for the AI assistant
    /// - Returns: The new conversation instance
    public func startConversation(systemPrompt: String? = nil) -> Conversation {
        let conversation = Conversation(
            id: UUID(),
            systemPrompt: systemPrompt,
            messages: []
        )
        self.activeConversation = conversation
        return conversation
    }

    /// Send a message in the active conversation
    /// - Parameter text: User message text
    /// - Returns: Assistant's response text
    /// - Throws: `IntelligenceError.noActiveConversation` if no active conversation
    public func sendMessage(_ text: String) async throws -> String {
        guard var conversation = activeConversation else {
            throw IntelligenceError.noActiveConversation
        }

        let userMessage = Message(role: .user, content: text)
        let response = try await provider.sendMessage(userMessage, in: conversation)

        // Update conversation history
        conversation.messages.append(userMessage)
        conversation.messages.append(response)
        self.activeConversation = conversation

        return response.content
    }

    /// Get the current conversation
    /// - Returns: Active conversation or nil
    public func currentConversation() -> Conversation? {
        activeConversation
    }

    /// End the active conversation
    public func endConversation() {
        activeConversation = nil
    }

    /// Get conversation history
    /// - Returns: Array of messages in the active conversation
    /// - Throws: `IntelligenceError.noActiveConversation` if no active conversation
    public func conversationHistory() throws -> [Message] {
        guard let conversation = activeConversation else {
            throw IntelligenceError.noActiveConversation
        }
        return conversation.messages
    }

    /// Estimate tokens used in the active conversation
    /// - Returns: Approximate token count
    /// - Throws: `IntelligenceError.noActiveConversation` if no active conversation
    public func estimateTokensUsed() throws -> Int {
        guard let conversation = activeConversation else {
            throw IntelligenceError.noActiveConversation
        }
        return provider.estimateTokens(for: conversation)
    }
}
