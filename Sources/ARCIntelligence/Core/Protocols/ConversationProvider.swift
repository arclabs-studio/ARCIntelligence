//
//  ConversationProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Protocol for providers that support multi-turn conversations.
///
/// Extends `IntelligenceProvider` with conversation-specific capabilities,
/// including message history management and context preservation.
public protocol ConversationProvider: IntelligenceProvider {
    /// Send a message within an existing conversation context
    /// - Parameters:
    ///   - message: The user message to send
    ///   - conversation: The conversation context
    /// - Returns: The assistant's response message
    /// - Throws: `IntelligenceError` if the request fails
    func sendMessage(
        _ message: Message,
        in conversation: Conversation
    ) async throws -> Message

    /// Continue a conversation with a new user message
    /// - Parameters:
    ///   - conversation: The existing conversation
    ///   - text: The new message text
    /// - Returns: The assistant's response message
    /// - Throws: `IntelligenceError` if the request fails
    func continueConversation(
        _ conversation: Conversation,
        with text: String
    ) async throws -> Message

    /// Estimate token count for a conversation
    /// - Parameter conversation: The conversation to analyze
    /// - Returns: Approximate token count
    func estimateTokens(for conversation: Conversation) -> Int
}
