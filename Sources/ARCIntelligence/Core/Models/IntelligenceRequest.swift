//
//  IntelligenceRequest.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Request for an intelligence provider completion.
public struct IntelligenceRequest: Sendable, Equatable {

    // MARK: - Properties

    /// The input prompt or text
    public let prompt: String

    /// Configuration for the completion
    public let configuration: CompletionConfiguration

    /// Optional conversation context
    public let conversation: Conversation?

    /// Request timestamp
    public let timestamp: Date

    // MARK: - Initialization

    public init(
        prompt: String,
        configuration: CompletionConfiguration = .default,
        conversation: Conversation? = nil,
        timestamp: Date = Date()
    ) {
        self.prompt = prompt
        self.configuration = configuration
        self.conversation = conversation
        self.timestamp = timestamp
    }
}
