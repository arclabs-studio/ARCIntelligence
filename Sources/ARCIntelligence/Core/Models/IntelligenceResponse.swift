//
//  IntelligenceResponse.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Response from an intelligence provider completion request.
public struct IntelligenceResponse: Sendable, Equatable {
    // MARK: - Properties

    /// The generated content
    public let content: String

    /// Number of tokens used in the request and response
    public let tokensUsed: Int

    /// Reason why generation finished
    public let finishReason: FinishReason

    /// Optional metadata from the provider
    public let metadata: [String: String]

    /// Grounding metadata from the provider, if grounding was enabled and supported.
    ///
    /// `nil` when the provider does not support grounding or grounding was not
    /// requested via `CompletionConfiguration.groundingEnabled`.
    public let groundingMetadata: GroundingMetadata?

    // MARK: - Initialization

    public init(content: String,
                tokensUsed: Int,
                finishReason: FinishReason = .completed,
                metadata: [String: String] = [:],
                groundingMetadata: GroundingMetadata? = nil) {
        self.content = content
        self.tokensUsed = tokensUsed
        self.finishReason = finishReason
        self.metadata = metadata
        self.groundingMetadata = groundingMetadata
    }

    // MARK: - Finish Reason

    /// Reason why the generation finished
    public enum FinishReason: String, Sendable, Codable, Equatable {
        /// Generation completed naturally
        case completed

        /// Hit maximum token limit
        case maxTokens

        /// Encountered a stop sequence
        case stopSequence

        /// Content was filtered
        case contentFilter

        /// Unknown or other reason
        case unknown
    }
}
