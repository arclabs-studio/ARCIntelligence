//
//  GeminiConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

/// Configuration for the Google Gemini provider.
///
/// Supports direct API key authentication for development and AIProxy
/// for production deployments where the API key should not be on-device.
///
/// This provider calls Google's native `v1` Gemini REST API directly
/// (`generativelanguage.googleapis.com`). It is intentionally independent of
/// `ARCFirebaseAI`, which routes through Firebase. Use both for resilience:
/// fall back to this provider when Firebase reports model overload.
///
/// ## Example
/// ```swift
/// // Development
/// let config = GeminiConfiguration(authentication: .apiKey("AIza..."))
///
/// // Production via AIProxy
/// let config = GeminiConfiguration(
///     authentication: .aiProxy(partialKey: "...", serviceURL: "https://...")
/// )
///
/// // Quick setup
/// let provider = ARCIntelligence.gemini(apiKey: "AIza...")
/// ```
public struct GeminiConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Authentication method for the Gemini API.
    public let authentication: GeminiAuthentication

    /// The model to use for completions.
    public let model: GeminiModel

    /// Default temperature for completions (0.0 = deterministic, 2.0 = most creative).
    public let defaultTemperature: Float

    /// Default maximum output tokens for completions.
    ///
    /// Gemini 2.0 Flash has an output limit of 8,192 tokens via this endpoint.
    /// This value is used when `CompletionConfiguration.maxTokens` is nil.
    public let defaultMaxTokens: Int

    /// Default instructions (system prompt) for the model.
    public let defaultInstructions: String?

    /// Maximum number of tool-calling rounds before stopping.
    ///
    /// Prevents infinite loops when the model keeps calling tools.
    public let maxToolRounds: Int

    // MARK: - Initialization

    public init(authentication: GeminiAuthentication,
                model: GeminiModel = .gemini2Flash,
                defaultTemperature: Float = 0.7,
                defaultMaxTokens: Int = 4096,
                defaultInstructions: String? = nil,
                maxToolRounds: Int = 10) {
        self.authentication = authentication
        self.model = model
        self.defaultTemperature = max(0.0, min(2.0, defaultTemperature))
        self.defaultMaxTokens = max(1, min(8192, defaultMaxTokens))
        self.defaultInstructions = defaultInstructions
        self.maxToolRounds = max(1, min(50, maxToolRounds))
    }

    // MARK: - Presets

    /// Configuration optimized for fast, economical responses.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Gemini 2.0 Flash-Lite with low temperature.
    public static func fast(authentication: GeminiAuthentication) -> GeminiConfiguration {
        GeminiConfiguration(authentication: authentication,
                            model: .gemini2FlashLite,
                            defaultTemperature: 0.3,
                            defaultMaxTokens: 2048)
    }

    /// Configuration optimized for balanced quality and cost.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Gemini 2.0 Flash with default settings.
    public static func balanced(authentication: GeminiAuthentication) -> GeminiConfiguration {
        GeminiConfiguration(authentication: authentication,
                            model: .gemini2Flash,
                            defaultTemperature: 0.7,
                            defaultMaxTokens: 4096)
    }

    /// Configuration optimized for maximum quality.
    /// - Parameter authentication: Authentication method.
    /// - Returns: Configuration using Gemini 1.5 Pro with a high token limit.
    public static func quality(authentication: GeminiAuthentication) -> GeminiConfiguration {
        GeminiConfiguration(authentication: authentication,
                            model: .gemini15Pro,
                            defaultTemperature: 0.5,
                            defaultMaxTokens: 8192)
    }
}

// MARK: - Authentication

/// Authentication method for the Gemini API.
public enum GeminiAuthentication: Sendable, Equatable {
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

/// Available Google Gemini models.
public enum GeminiModel: Sendable, Hashable {
    /// Gemini 2.0 Flash — balanced speed and quality (default).
    case gemini2Flash

    /// Gemini 2.0 Flash-Lite — fastest, most economical.
    case gemini2FlashLite

    /// Gemini 1.5 Pro — maximum capability.
    case gemini15Pro

    /// Gemini 1.5 Flash — balanced for the 1.5 generation.
    case gemini15Flash

    /// Custom model identifier for future or preview models.
    case custom(String)

    /// The model identifier string used in the API URL path.
    public var modelId: String {
        switch self {
        case .gemini2Flash:
            "gemini-2.0-flash"
        case .gemini2FlashLite:
            "gemini-2.0-flash-lite"
        case .gemini15Pro:
            "gemini-1.5-pro"
        case .gemini15Flash:
            "gemini-1.5-flash"
        case let .custom(id):
            id
        }
    }
}
