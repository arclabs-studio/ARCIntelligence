//
//  ARCIntelligence+Anthropic.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - Anthropic Factory Methods

extension ARCIntelligence {
    /// Create an Anthropic Claude provider with the given configuration.
    ///
    /// ## Example
    /// ```swift
    /// let config = AnthropicConfiguration(
    ///     authentication: .apiKey("sk-ant-..."),
    ///     model: .sonnet
    /// )
    /// let provider = ARCIntelligence.anthropic(configuration: config)
    /// ```
    ///
    /// - Parameter configuration: The Anthropic provider configuration.
    /// - Returns: Configured Anthropic provider.
    public static func anthropic(configuration: AnthropicConfiguration) -> AnthropicProvider {
        logger.debug("Creating AnthropicProvider with custom configuration")
        return AnthropicProvider(configuration: configuration)
    }

    /// Create an Anthropic Claude provider with an API key (development convenience).
    ///
    /// Uses Sonnet as the default model with standard settings.
    ///
    /// - Parameter apiKey: The Anthropic API key.
    /// - Returns: Configured Anthropic provider.
    public static func anthropic(apiKey: String) -> AnthropicProvider {
        logger.debug("Creating AnthropicProvider with API key")
        return AnthropicProvider(configuration: AnthropicConfiguration(authentication: .apiKey(apiKey)))
    }

    /// Create an Anthropic Claude provider with AIProxy authentication (production).
    ///
    /// - Parameters:
    ///   - aiProxyPartialKey: The AIProxy partial key.
    ///   - serviceURL: The AIProxy service URL.
    /// - Returns: Configured Anthropic provider.
    public static func anthropic(aiProxyPartialKey: String,
                                 serviceURL: String) -> AnthropicProvider {
        logger.debug("Creating AnthropicProvider with AIProxy")
        let authentication = AnthropicAuthentication.aiProxy(partialKey: aiProxyPartialKey,
                                                             serviceURL: serviceURL)
        return AnthropicProvider(configuration: AnthropicConfiguration(authentication: authentication))
    }

    /// Create a tool provider backed by Anthropic Claude.
    /// - Parameter anthropicConfiguration: The Anthropic configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(anthropicConfiguration: AnthropicConfiguration) -> some ToolProvider {
        logger.debug("Creating ToolProvider (Anthropic)")
        return AnthropicProvider(configuration: anthropicConfiguration)
    }

    /// Create a generable provider backed by Anthropic Claude.
    /// - Parameter anthropicConfiguration: The Anthropic configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(anthropicConfiguration: AnthropicConfiguration) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (Anthropic)")
        return AnthropicProvider(configuration: anthropicConfiguration)
    }
}
