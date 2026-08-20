//
//  ConversationalAssistant.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

/// Actor for managing conversational AI interactions.
///
/// Maintains conversation state and handles multi-turn dialogues with an AI assistant.
/// Thread-safe through actor isolation.
public actor ConversationalAssistant {
    // MARK: - Properties

    private let provider: ConversationProvider
    private var activeConversation: Conversation?
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "ConversationalAssistant")

    // MARK: - Initialization

    public init(provider: ConversationProvider) {
        self.provider = provider
    }

    // MARK: - Public Methods

    /// Start a new conversation with optional system prompt
    /// - Parameter systemPrompt: Instructions for the AI assistant
    /// - Returns: The new conversation instance
    public func startConversation(systemPrompt: String? = nil) -> Conversation {
        let conversation = Conversation(id: UUID(),
                                        systemPrompt: systemPrompt,
                                        messages: [])
        activeConversation = conversation

        logger.info("Started new conversation", metadata: ["conversationId": .public(conversation.id.uuidString),
                                                           "hasSystemPrompt": .public("\(systemPrompt != nil)")])

        return conversation
    }

    /// Send a message in the active conversation
    /// - Parameter text: User message text
    /// - Returns: Assistant's response text
    /// - Throws: `IntelligenceError.noActiveConversation` if no active conversation
    public func sendMessage(_ text: String) async throws -> String {
        guard var conversation = activeConversation else {
            logger.warning("Attempted to send message without active conversation")
            throw IntelligenceError.noActiveConversation
        }

        logger.debug("Sending user message", metadata: ["conversationId": .public(conversation.id.uuidString),
                                                        "messageLength": .public("\(text.count)")])

        let userMessage = Message(role: .user, content: text)
        let response = try await provider.sendMessage(userMessage, in: conversation)

        // Update conversation history
        conversation.messages.append(userMessage)
        conversation.messages.append(response)
        activeConversation = conversation

        // swiftlint:disable line_length
        logger.info("Received assistant response", metadata: ["conversationId": .public(conversation.id.uuidString),
                                                              "responseLength": .public("\(response.content.count)"),
                                                              "totalMessages": .public("\(conversation.messages.count)")])
        // swiftlint:enable line_length

        return response.content
    }

    /// Get the current conversation
    /// - Returns: Active conversation or nil
    public func currentConversation() -> Conversation? {
        activeConversation
    }

    /// End the active conversation
    public func endConversation() {
        if let conversation = activeConversation {
            logger.info("Ending conversation", metadata: ["conversationId": .public(conversation.id.uuidString),
                                                          "totalMessages": .public("\(conversation.messages.count)")])
        }
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
