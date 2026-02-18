//
//  ARCIntelligence+Grok.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - Grok Factory Methods

extension ARCIntelligence {
    /// Create a Grok (xAI) provider with the given configuration.
    ///
    /// ## Example
    /// ```swift
    /// let config = GrokConfiguration(
    ///     authentication: .apiKey("xai-..."),
    ///     model: .grok3Fast
    /// )
    /// let provider = ARCIntelligence.grok(configuration: config)
    /// ```
    ///
    /// - Parameter configuration: The Grok provider configuration.
    /// - Returns: Configured Grok provider.
    public static func grok(configuration: GrokConfiguration) -> GrokProvider {
        logger.debug("Creating GrokProvider with custom configuration")
        return GrokProvider(configuration: configuration)
    }

    /// Create a Grok (xAI) provider with an API key (development convenience).
    ///
    /// Uses Grok 3 Fast as the default model with standard settings.
    ///
    /// - Parameter apiKey: The xAI API key.
    /// - Returns: Configured Grok provider.
    public static func grok(apiKey: String) -> GrokProvider {
        logger.debug("Creating GrokProvider with API key")
        return GrokProvider(configuration: GrokConfiguration(authentication: .apiKey(apiKey)))
    }

    /// Create a Grok (xAI) provider with AIProxy authentication (production).
    ///
    /// - Parameters:
    ///   - aiProxyPartialKey: The AIProxy partial key.
    ///   - serviceURL: The AIProxy service URL.
    /// - Returns: Configured Grok provider.
    public static func grok(aiProxyPartialKey: String,
                            serviceURL: String) -> GrokProvider {
        logger.debug("Creating GrokProvider with AIProxy")
        let authentication = GrokAuthentication.aiProxy(partialKey: aiProxyPartialKey,
                                                        serviceURL: serviceURL)
        return GrokProvider(configuration: GrokConfiguration(authentication: authentication))
    }

    /// Create a tool provider backed by Grok (xAI).
    /// - Parameter grokConfiguration: The Grok configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(grokConfiguration: GrokConfiguration) -> some ToolProvider {
        logger.debug("Creating ToolProvider (Grok)")
        return GrokProvider(configuration: grokConfiguration)
    }

    /// Create a generable provider backed by Grok (xAI).
    /// - Parameter grokConfiguration: The Grok configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(grokConfiguration: GrokConfiguration) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (Grok)")
        return GrokProvider(configuration: grokConfiguration)
    }
}
