//
//  FoundationModelsCapabilities.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Capabilities available in the Foundation Models provider.
public struct FoundationModelsCapabilities: Sendable, Equatable {
    // MARK: - Properties

    /// Supports text completion
    public let supportsCompletion: Bool

    /// Supports streaming responses
    public let supportsStreaming: Bool

    /// Supports conversation history
    public let supportsConversation: Bool

    /// Supports embeddings generation
    public let supportsEmbeddings: Bool

    /// Maximum context window size (in tokens)
    public let maxContextWindow: Int

    // MARK: - Initialization

    public init(
        supportsCompletion: Bool = true,
        supportsStreaming: Bool = true,
        supportsConversation: Bool = true,
        supportsEmbeddings: Bool = false,
        maxContextWindow: Int = 4096
    ) {
        self.supportsCompletion = supportsCompletion
        self.supportsStreaming = supportsStreaming
        self.supportsConversation = supportsConversation
        self.supportsEmbeddings = supportsEmbeddings
        self.maxContextWindow = maxContextWindow
    }

    // MARK: - Default Capabilities

    /// Default capabilities for iOS 18.0+
    public static let `default` = FoundationModelsCapabilities()
}
