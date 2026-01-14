//
//  CompletionConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Configuration for text completion requests.
///
/// Controls the behavior of the AI provider when generating responses,
/// including creativity (temperature), output length, and stopping conditions.
public struct CompletionConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Randomness in generation (0.0 = deterministic, 1.0 = maximum creativity)
    public let temperature: Float

    /// Maximum number of tokens to generate (nil = provider default)
    public let maxTokens: Int?

    /// System prompt to guide behavior (provider-specific)
    public let systemPrompt: String?

    /// Sequences that stop generation when encountered
    public let stopSequences: [String]

    /// Nucleus sampling threshold (0.0 - 1.0, nil = disabled)
    public let topP: Float?

    // MARK: - Initialization

    public init(
        temperature: Float = 0.7,
        maxTokens: Int? = nil,
        systemPrompt: String? = nil,
        stopSequences: [String] = [],
        topP: Float? = nil
    ) {
        self.temperature = max(0.0, min(1.0, temperature))
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
        self.stopSequences = stopSequences
        self.topP = topP.map { max(0.0, min(1.0, $0)) }
    }

    // MARK: - Presets

    /// Default configuration optimized for general use
    public static let `default` = CompletionConfiguration()

    /// Configuration optimized for creative writing
    public static let creative = CompletionConfiguration(
        temperature: 0.9,
        topP: 0.95
    )

    /// Configuration optimized for factual/analytical responses
    public static let factual = CompletionConfiguration(
        temperature: 0.3,
        topP: 0.9
    )
}
