//
//  Message.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Represents a single message in a conversation.
public struct Message: Sendable, Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier for the message
    public let id: UUID

    /// Message role (user, assistant, system)
    public let role: Role

    /// Message content
    public let content: String

    /// Timestamp when the message was created
    public let timestamp: Date

    /// Optional metadata (token count, model used, etc.)
    public let metadata: [String: String]

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }

    // MARK: - Role

    /// Message role in a conversation
    public enum Role: String, Sendable, Codable {
        case system
        case user
        case assistant
    }
}
