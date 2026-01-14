//
//  Conversation.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Represents a multi-turn conversation with an AI assistant.
public struct Conversation: Sendable, Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier for the conversation
    public let id: UUID

    /// Optional system prompt to guide the assistant's behavior
    public let systemPrompt: String?

    /// Array of messages in the conversation
    public var messages: [Message]

    /// Timestamp when the conversation was created
    public let createdAt: Date

    /// Timestamp when the conversation was last updated
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        systemPrompt: String? = nil,
        messages: [Message] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.systemPrompt = systemPrompt
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total number of messages in the conversation
    public var messageCount: Int {
        messages.count
    }

    /// Check if the conversation is empty
    public var isEmpty: Bool {
        messages.isEmpty
    }
}
