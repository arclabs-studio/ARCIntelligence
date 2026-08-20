//
//  GrokConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

/// Configuration for the Grok (xAI) provider.
///
/// Supports direct API key authentication for development and AIProxy
/// for production deployments where the API key should not be on-device.
///
/// ## Example
/// ```swift
/// // Development
/// let config = GrokConfiguration(authentication: .apiKey("xai-..."))
///
/// // Production via AIProxy
/// let config = GrokConfiguration(
///     authentication: .aiProxy(partialKey: "...", serviceURL: "https://...")
/// )
///
/// // Quick setup
/// let provider = ARCIntelligence.grok(apiKey: "xai-...")
/// ```
public struct GrokConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Authentication method for the xAI API.
    public let authentication: GrokAuthentication

    /// The model to use for completions.
    public let model: GrokModel

    /// Default temperature for completions (0.0 = deterministic, 2.0 = maximum creativity).
    public let defaultTemperature: Float

    /// Default maximum tokens for completions.
    public let defaultMaxTokens: Int

    /// Default instructions (system prompt) for the model.
    public let defaultInstructions: String?

    /// Maximum number of tool-calling rounds before stopping.
    public let maxToolRounds: Int

    // MARK: - Initialization

    public init(authentication: GrokAuthentication,
                model: GrokModel = .grok3Fast,
                defaultTemperature: Float = 0.7,
                defaultMaxTokens: Int = 4096,
                defaultInstructions: String? = nil,
                maxToolRounds: Int = 10) {
        self.authentication = authentication
        self.model = model
        self.defaultTemperature = max(0.0, min(2.0, defaultTemperature))
        self.defaultMaxTokens = max(1, min(128_000, defaultMaxTokens))
        self.defaultInstructions = defaultInstructions
        self.maxToolRounds = max(1, min(50, maxToolRounds))
    }

    // MARK: - Presets

    /// Configuration optimized for fast, economical responses.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Grok 3 Fast with low temperature.
    public static func fast(authentication: GrokAuthentication) -> GrokConfiguration {
        GrokConfiguration(authentication: authentication,
                          model: .grok3Fast,
                          defaultTemperature: 0.3,
                          defaultMaxTokens: 2048)
    }

    /// Configuration optimized for balanced quality and cost.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Grok 3 with default settings.
    public static func balanced(authentication: GrokAuthentication) -> GrokConfiguration {
        GrokConfiguration(authentication: authentication,
                          model: .grok3,
                          defaultTemperature: 0.7,
                          defaultMaxTokens: 4096)
    }

    /// Configuration optimized for maximum quality.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Grok 3 with high token limit.
    public static func quality(authentication: GrokAuthentication) -> GrokConfiguration {
        GrokConfiguration(authentication: authentication,
                          model: .grok3,
                          defaultTemperature: 0.5,
                          defaultMaxTokens: 8192)
    }
}

// MARK: - Authentication

/// Authentication method for the xAI API.
public enum GrokAuthentication: Sendable, Equatable {
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

/// Available Grok (xAI) models.
public enum GrokModel: Sendable, Hashable {
    /// Grok 3 - Full capability model.
    case grok3

    /// Grok 3 Fast - Optimized for speed (default).
    case grok3Fast

    /// Custom model identifier for future models.
    case custom(String)

    /// The model identifier string sent to the API.
    public var modelId: String {
        switch self {
        case .grok3:
            "grok-3"
        case .grok3Fast:
            "grok-3-fast"
        case let .custom(id):
            id
        }
    }
}
