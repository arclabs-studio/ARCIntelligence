//
//  AnthropicConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation

/// Configuration for the Anthropic Claude provider.
///
/// Supports direct API key authentication for development and AIProxy
/// for production deployments where the API key should not be on-device.
///
/// ## Example
/// ```swift
/// // Development
/// let config = AnthropicConfiguration(authentication: .apiKey("sk-ant-..."))
///
/// // Production via AIProxy
/// let config = AnthropicConfiguration(
///     authentication: .aiProxy(partialKey: "...", serviceURL: "https://...")
/// )
///
/// // Quick setup
/// let provider = ARCIntelligence.anthropic(apiKey: "sk-ant-...")
/// ```
public struct AnthropicConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Authentication method for the Anthropic API.
    public let authentication: AnthropicAuthentication

    /// The model to use for completions.
    public let model: AnthropicModel

    /// Default temperature for completions (0.0 = deterministic, 1.0 = creative).
    public let defaultTemperature: Float

    /// Default maximum tokens for completions.
    ///
    /// The Anthropic API requires `max_tokens` on every request.
    /// This value is used when `CompletionConfiguration.maxTokens` is nil.
    public let defaultMaxTokens: Int

    /// Default instructions (system prompt) for the model.
    public let defaultInstructions: String?

    /// Maximum number of tool-calling rounds before stopping.
    ///
    /// Prevents infinite loops when the model keeps calling tools.
    public let maxToolRounds: Int

    // MARK: - Initialization

    public init(
        authentication: AnthropicAuthentication,
        model: AnthropicModel = .sonnet,
        defaultTemperature: Float = 0.7,
        defaultMaxTokens: Int = 4096,
        defaultInstructions: String? = nil,
        maxToolRounds: Int = 10
    ) {
        self.authentication = authentication
        self.model = model
        self.defaultTemperature = max(0.0, min(1.0, defaultTemperature))
        self.defaultMaxTokens = max(1, min(128_000, defaultMaxTokens))
        self.defaultInstructions = defaultInstructions
        self.maxToolRounds = max(1, min(50, maxToolRounds))
    }

    // MARK: - Presets

    /// Configuration optimized for fast, economical responses.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Claude Haiku with low temperature.
    public static func fast(authentication: AnthropicAuthentication) -> AnthropicConfiguration {
        AnthropicConfiguration(
            authentication: authentication,
            model: .haiku,
            defaultTemperature: 0.3,
            defaultMaxTokens: 2048
        )
    }

    /// Configuration optimized for balanced quality and cost.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Claude Sonnet with default settings.
    public static func balanced(authentication: AnthropicAuthentication) -> AnthropicConfiguration {
        AnthropicConfiguration(
            authentication: authentication,
            model: .sonnet,
            defaultTemperature: 0.7,
            defaultMaxTokens: 4096
        )
    }

    /// Configuration optimized for maximum quality.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Claude Opus with high token limit.
    public static func quality(authentication: AnthropicAuthentication) -> AnthropicConfiguration {
        AnthropicConfiguration(
            authentication: authentication,
            model: .opus,
            defaultTemperature: 0.5,
            defaultMaxTokens: 8192
        )
    }
}

// MARK: - Authentication

/// Authentication method for the Anthropic API.
public enum AnthropicAuthentication: Sendable, Equatable {
    /// Direct API key authentication.
    ///
    /// Suitable for development and server-side usage.
    /// **Do not ship API keys in client apps.**
    case apiKey(String)

    /// AIProxy-based authentication for production iOS apps.
    ///
    /// - Parameters:
    ///   - partialKey: The partial key provided by AIProxy.
    ///   - serviceURL: The AIProxy service URL.
    case aiProxy(partialKey: String, serviceURL: String)
}

// MARK: - Model

/// Available Anthropic Claude models.
public enum AnthropicModel: Sendable, Hashable {
    /// Claude 3.5 Haiku - Fast, economical.
    case haiku

    /// Claude Sonnet 4.5 - Balanced quality and speed (default).
    case sonnet

    /// Claude Opus 4.6 - Maximum capability.
    case opus

    /// Custom model identifier for future or beta models.
    case custom(String)

    /// The model identifier string sent to the API.
    public var modelId: String {
        switch self {
        case .haiku:
            "claude-3-5-haiku-latest"
        case .sonnet:
            "claude-sonnet-4-5-20250929"
        case .opus:
            "claude-opus-4-6"
        case let .custom(id):
            id
        }
    }
}
