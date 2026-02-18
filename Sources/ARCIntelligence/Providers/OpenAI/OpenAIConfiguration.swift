//
//  OpenAIConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

/// Configuration for the OpenAI provider.
///
/// Supports direct API key authentication for development and AIProxy
/// for production deployments where the API key should not be on-device.
///
/// ## Example
/// ```swift
/// // Development
/// let config = OpenAIConfiguration(authentication: .apiKey("sk-..."))
///
/// // Production via AIProxy
/// let config = OpenAIConfiguration(
///     authentication: .aiProxy(partialKey: "...", serviceURL: "https://...")
/// )
///
/// // Quick setup
/// let provider = ARCIntelligence.openAI(apiKey: "sk-...")
/// ```
public struct OpenAIConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Authentication method for the OpenAI API.
    public let authentication: OpenAIAuthentication

    /// The model to use for completions.
    public let model: OpenAIModel

    /// Default temperature for completions (0.0 = deterministic, 2.0 = maximum creativity).
    public let defaultTemperature: Float

    /// Default maximum tokens for completions.
    public let defaultMaxTokens: Int

    /// Default instructions (system prompt) for the model.
    public let defaultInstructions: String?

    /// Maximum number of tool-calling rounds before stopping.
    public let maxToolRounds: Int

    /// Optional organization ID for the OpenAI API.
    public let organization: String?

    // MARK: - Initialization

    public init(authentication: OpenAIAuthentication,
                model: OpenAIModel = .gpt4oMini,
                defaultTemperature: Float = 0.7,
                defaultMaxTokens: Int = 4096,
                defaultInstructions: String? = nil,
                maxToolRounds: Int = 10,
                organization: String? = nil) {
        self.authentication = authentication
        self.model = model
        self.defaultTemperature = max(0.0, min(2.0, defaultTemperature))
        self.defaultMaxTokens = max(1, min(128_000, defaultMaxTokens))
        self.defaultInstructions = defaultInstructions
        self.maxToolRounds = max(1, min(50, maxToolRounds))
        self.organization = organization
    }

    // MARK: - Presets

    /// Configuration optimized for fast, economical responses.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using GPT-4o Mini with low temperature.
    public static func fast(authentication: OpenAIAuthentication) -> OpenAIConfiguration {
        OpenAIConfiguration(authentication: authentication,
                            model: .gpt4oMini,
                            defaultTemperature: 0.3,
                            defaultMaxTokens: 2048)
    }

    /// Configuration optimized for balanced quality and cost.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using GPT-4o with default settings.
    public static func balanced(authentication: OpenAIAuthentication) -> OpenAIConfiguration {
        OpenAIConfiguration(authentication: authentication,
                            model: .gpt4o,
                            defaultTemperature: 0.7,
                            defaultMaxTokens: 4096)
    }

    /// Configuration optimized for maximum quality.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using o3-mini with high token limit.
    public static func quality(authentication: OpenAIAuthentication) -> OpenAIConfiguration {
        OpenAIConfiguration(authentication: authentication,
                            model: .o3Mini,
                            defaultTemperature: 0.5,
                            defaultMaxTokens: 8192)
    }
}

// MARK: - Authentication

/// Authentication method for the OpenAI API.
public enum OpenAIAuthentication: Sendable, Equatable {
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

/// Available OpenAI models.
public enum OpenAIModel: Sendable, Hashable {
    /// GPT-4o Mini - Fast, economical (default).
    case gpt4oMini

    /// GPT-4o - Balanced quality and speed.
    case gpt4o

    /// o3-mini - Advanced reasoning.
    case o3Mini

    /// Custom model identifier for future or fine-tuned models.
    case custom(String)

    /// The model identifier string sent to the API.
    public var modelId: String {
        switch self {
        case .gpt4oMini:
            "gpt-4o-mini"
        case .gpt4o:
            "gpt-4o"
        case .o3Mini:
            "o3-mini"
        case let .custom(id):
            id
        }
    }
}
