//
//  ARCIntelligence+Gemini.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

// MARK: - Gemini Factory Methods

extension ARCIntelligence {
    /// Create a Gemini provider with the given configuration.
    ///
    /// Calls Google's native `v1` Gemini REST API directly. For Firebase-proxied
    /// Gemini access, use `ARCFirebaseAI` instead.
    ///
    /// ## Example
    /// ```swift
    /// let config = GeminiConfiguration(
    ///     authentication: .apiKey("AIza..."),
    ///     model: .gemini2Flash
    /// )
    /// let provider = ARCIntelligence.gemini(configuration: config)
    /// ```
    ///
    /// - Parameter configuration: The Gemini provider configuration.
    /// - Returns: Configured Gemini provider.
    public static func gemini(configuration: GeminiConfiguration) -> GeminiProvider {
        logger.debug("Creating GeminiProvider with custom configuration")
        return GeminiProvider(configuration: configuration)
    }

    /// Create a Gemini provider with an API key (development convenience).
    ///
    /// Uses Gemini 2.0 Flash as the default model with standard settings.
    ///
    /// - Important: Do not ship API keys in production apps. Use
    ///   `gemini(aiProxyPartialKey:serviceURL:)` or `gemini(configuration:)` with
    ///   `.aiProxy` authentication for production deployments.
    ///
    /// - Parameter apiKey: A Google AI Studio API key (`AIza...`).
    /// - Returns: Configured Gemini provider.
    public static func gemini(apiKey: String) -> GeminiProvider {
        logger.debug("Creating GeminiProvider with API key")
        return GeminiProvider(configuration: GeminiConfiguration(authentication: .apiKey(apiKey)))
    }

    /// Create a Gemini provider with AIProxy authentication (production).
    ///
    /// - Parameters:
    ///   - aiProxyPartialKey: The AIProxy partial key.
    ///   - serviceURL: The AIProxy service URL.
    /// - Returns: Configured Gemini provider.
    public static func gemini(aiProxyPartialKey: String,
                              serviceURL: String) -> GeminiProvider {
        logger.debug("Creating GeminiProvider with AIProxy")
        let authentication = GeminiAuthentication.aiProxy(partialKey: aiProxyPartialKey,
                                                          serviceURL: serviceURL)
        return GeminiProvider(configuration: GeminiConfiguration(authentication: authentication))
    }

    /// Create a tool provider backed by Gemini.
    /// - Parameter geminiConfiguration: The Gemini configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(geminiConfiguration: GeminiConfiguration) -> some ToolProvider {
        logger.debug("Creating ToolProvider (Gemini)")
        return GeminiProvider(configuration: geminiConfiguration)
    }

    /// Create a generable provider backed by Gemini.
    /// - Parameter geminiConfiguration: The Gemini configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(geminiConfiguration: GeminiConfiguration) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (Gemini)")
        return GeminiProvider(configuration: geminiConfiguration)
    }
}
