//
//  FoundationModelsConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Configuration for the Foundation Models provider.
///
/// This configuration maps to Apple's Foundation Models framework options
/// available in iOS 26+, macOS 26+, and visionOS 26+.
public struct FoundationModelsConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Default temperature for completions (0.0 = deterministic, 2.0 = creative)
    ///
    /// Maps to `GenerationOptions.temperature` in Apple's API.
    public let defaultTemperature: Float

    /// Maximum context window size in tokens
    ///
    /// Apple's on-device model supports up to 4096 tokens per session.
    /// This includes instructions, all prompts, and all outputs.
    public let maxContextTokens: Int

    /// Enable on-device processing only (no cloud fallback)
    public let onDeviceOnly: Bool

    /// Guardrail mode for content safety
    ///
    /// Maps to `SystemLanguageModel.Guardrails` in Apple's API.
    public let guardrailMode: GuardrailMode

    /// Default instructions for the model
    ///
    /// Instructions define the model's role and behavior. They have higher
    /// priority than prompts and affect all interactions in a session.
    public let defaultInstructions: String?

    // MARK: - Nested Types

    /// Guardrail modes for content safety.
    ///
    /// Maps to `SystemLanguageModel.Guardrails` in Apple's Foundation Models API.
    public enum GuardrailMode: Sendable, Equatable {
        /// Default guardrails that block harmful content in input and output
        case standard

        /// Permissive mode that allows reasoning about sensitive source material
        ///
        /// Use this when your app needs to process content that may contain
        /// sensitive topics (e.g., tagging conversations, explaining study notes).
        /// Only works for string generation, not guided generation.
        case permissiveContentTransformations
    }

    // MARK: - Initialization

    public init(
        defaultTemperature: Float = 0.7,
        maxContextTokens: Int = 4096,
        onDeviceOnly: Bool = true,
        guardrailMode: GuardrailMode = .standard,
        defaultInstructions: String? = nil
    ) {
        // Apple's API supports temperature up to 2.0 for increased creativity
        self.defaultTemperature = max(0.0, min(2.0, defaultTemperature))
        // Apple's on-device model has a hard limit of 4096 tokens
        self.maxContextTokens = max(1, min(4096, maxContextTokens))
        self.onDeviceOnly = onDeviceOnly
        self.guardrailMode = guardrailMode
        self.defaultInstructions = defaultInstructions
    }

    // MARK: - Presets

    /// Default configuration
    public static let `default` = FoundationModelsConfiguration()

    /// Configuration optimized for privacy (on-device only, standard guardrails)
    public static let privacy = FoundationModelsConfiguration(
        onDeviceOnly: true,
        guardrailMode: .standard
    )

    /// Configuration optimized for creative tasks (higher temperature)
    public static let creative = FoundationModelsConfiguration(
        defaultTemperature: 1.5,
        guardrailMode: .standard
    )

    /// Configuration for content analysis (permissive guardrails)
    ///
    /// Use this when your app needs to analyze or transform content that
    /// may contain sensitive material, such as chat moderation or study apps.
    public static let contentAnalysis = FoundationModelsConfiguration(
        defaultTemperature: 0.3,
        guardrailMode: .permissiveContentTransformations
    )

    /// Configuration for factual/deterministic responses
    public static let factual = FoundationModelsConfiguration(
        defaultTemperature: 0.0,
        guardrailMode: .standard
    )
}
