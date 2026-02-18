//
//  ARCIntelligence+OpenAI.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - OpenAI Factory Methods

extension ARCIntelligence {
    /// Create an OpenAI provider with the given configuration.
    ///
    /// ## Example
    /// ```swift
    /// let config = OpenAIConfiguration(
    ///     authentication: .apiKey("sk-..."),
    ///     model: .gpt4o
    /// )
    /// let provider = ARCIntelligence.openAI(configuration: config)
    /// ```
    ///
    /// - Parameter configuration: The OpenAI provider configuration.
    /// - Returns: Configured OpenAI provider.
    public static func openAI(configuration: OpenAIConfiguration) -> OpenAIProvider {
        logger.debug("Creating OpenAIProvider with custom configuration")
        return OpenAIProvider(configuration: configuration)
    }

    /// Create an OpenAI provider with an API key (development convenience).
    ///
    /// Uses GPT-4o Mini as the default model with standard settings.
    ///
    /// - Parameter apiKey: The OpenAI API key.
    /// - Returns: Configured OpenAI provider.
    public static func openAI(apiKey: String) -> OpenAIProvider {
        logger.debug("Creating OpenAIProvider with API key")
        return OpenAIProvider(configuration: OpenAIConfiguration(authentication: .apiKey(apiKey)))
    }

    /// Create an OpenAI provider with AIProxy authentication (production).
    ///
    /// - Parameters:
    ///   - aiProxyPartialKey: The AIProxy partial key.
    ///   - serviceURL: The AIProxy service URL.
    /// - Returns: Configured OpenAI provider.
    public static func openAI(aiProxyPartialKey: String,
                              serviceURL: String) -> OpenAIProvider {
        logger.debug("Creating OpenAIProvider with AIProxy")
        let authentication = OpenAIAuthentication.aiProxy(partialKey: aiProxyPartialKey,
                                                          serviceURL: serviceURL)
        return OpenAIProvider(configuration: OpenAIConfiguration(authentication: authentication))
    }

    /// Create a tool provider backed by OpenAI.
    /// - Parameter openAIConfiguration: The OpenAI configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(openAIConfiguration: OpenAIConfiguration) -> some ToolProvider {
        logger.debug("Creating ToolProvider (OpenAI)")
        return OpenAIProvider(configuration: openAIConfiguration)
    }

    /// Create a generable provider backed by OpenAI.
    /// - Parameter openAIConfiguration: The OpenAI configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(openAIConfiguration: OpenAIConfiguration) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (OpenAI)")
        return OpenAIProvider(configuration: openAIConfiguration)
    }
}
