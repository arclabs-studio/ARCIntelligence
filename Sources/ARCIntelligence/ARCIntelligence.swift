//
//  ARCIntelligence.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

/// Main public API for ARCIntelligence package.
///
/// ARCIntelligence provides AI capabilities for iOS and macOS apps through
/// a clean, protocol-based architecture that abstracts different AI providers.
///
/// ## Topics
///
/// ### Core Protocols
/// - ``IntelligenceProvider``
/// - ``ConversationProvider``
/// - ``RecommendationProvider``
/// - ``EmbeddingProvider``
/// - ``GenerableProvider``
/// - ``ToolProvider``
/// - ``ContentTaggingProvider``
///
/// ### Providers
/// - ``FoundationModelsProvider``
/// - ``FoundationModelsConfiguration``
/// - ``AnthropicProvider``
/// - ``AnthropicConfiguration``
/// - ``AnthropicModel``
/// - ``AnthropicAuthentication``
///
/// ### Use Cases
/// - ``ConversationalAssistant``
/// - ``RecommendationEngine``
/// - ``SemanticSearch``
///
/// ### Models
/// - ``Message``
/// - ``Conversation``
/// - ``Recommendation``
/// - ``Embedding``
/// - ``IntelligenceResponse``
/// - ``CompletionConfiguration``
/// - ``ContentTag``
/// - ``TagCategory``
/// - ``ToolCallRecord``
/// - ``IntelligenceTool``
/// - ``SessionTranscript``
/// - ``TranscriptEntry``
///
/// ### Utilities
/// - ``PromptBuilder``
/// - ``TokenCounter``
///
/// ### Errors
/// - ``IntelligenceError``
public enum ARCIntelligence {
    // MARK: - Version

    /// Current version of ARCIntelligence
    public static let version = "1.0.0"

    // MARK: - Logging

    /// Shared logger for the ARCIntelligence package.
    static let logger = ARCLogger(
        subsystem: "com.arclabs.intelligence",
        category: "ARCIntelligence"
    )

    // MARK: - Factory Methods

    /// Create a Foundation Models provider with default configuration
    /// - Returns: Configured Foundation Models provider
    public static func foundationModels() -> FoundationModelsProvider {
        logger.debug("Creating FoundationModelsProvider with default configuration")
        return FoundationModelsProvider(configuration: .default)
    }

    /// Create a Foundation Models provider with custom configuration
    /// - Parameter configuration: Custom configuration
    /// - Returns: Configured Foundation Models provider
    public static func foundationModels(
        configuration: FoundationModelsConfiguration
    ) -> FoundationModelsProvider {
        logger.debug("Creating FoundationModelsProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
    }

    // MARK: - Anthropic Factory Methods

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
    public static func anthropic(
        configuration: AnthropicConfiguration
    ) -> AnthropicProvider {
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
        return AnthropicProvider(
            configuration: AnthropicConfiguration(authentication: .apiKey(apiKey))
        )
    }

    /// Create an Anthropic Claude provider with AIProxy authentication (production).
    ///
    /// - Parameters:
    ///   - aiProxyPartialKey: The AIProxy partial key.
    ///   - serviceURL: The AIProxy service URL.
    /// - Returns: Configured Anthropic provider.
    public static func anthropic(
        aiProxyPartialKey: String,
        serviceURL: String
    ) -> AnthropicProvider {
        logger.debug("Creating AnthropicProvider with AIProxy")
        return AnthropicProvider(
            configuration: AnthropicConfiguration(
                authentication: .aiProxy(partialKey: aiProxyPartialKey, serviceURL: serviceURL)
            )
        )
    }

    /// Create a tool provider backed by Anthropic Claude.
    /// - Parameter anthropicConfiguration: The Anthropic configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(
        anthropicConfiguration: AnthropicConfiguration
    ) -> some ToolProvider {
        logger.debug("Creating ToolProvider (Anthropic)")
        return AnthropicProvider(configuration: anthropicConfiguration)
    }

    /// Create a generable provider backed by Anthropic Claude.
    /// - Parameter anthropicConfiguration: The Anthropic configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(
        anthropicConfiguration: AnthropicConfiguration
    ) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (Anthropic)")
        return AnthropicProvider(configuration: anthropicConfiguration)
    }

    // MARK: - Use Case Factories

    /// Create a conversational assistant with a provider
    /// - Parameter provider: The conversation provider to use
    /// - Returns: Configured conversational assistant
    public static func conversationalAssistant(
        provider: ConversationProvider
    ) -> ConversationalAssistant {
        logger.debug("Creating ConversationalAssistant")
        return ConversationalAssistant(provider: provider)
    }

    /// Create a recommendation engine with a provider
    /// - Parameter provider: The recommendation provider to use
    /// - Returns: Configured recommendation engine
    public static func recommendationEngine(
        provider: RecommendationProvider
    ) -> RecommendationEngine {
        logger.debug("Creating RecommendationEngine")
        return RecommendationEngine(provider: provider)
    }

    /// Create a semantic search engine with a provider
    /// - Parameter provider: The embedding provider to use
    /// - Returns: Configured semantic search engine
    public static func semanticSearch(
        provider: EmbeddingProvider
    ) -> SemanticSearch {
        logger.debug("Creating SemanticSearch")
        return SemanticSearch(provider: provider)
    }

    // MARK: - Specialized Provider Factories

    /// Create a generable provider for structured output generation.
    ///
    /// Uses Foundation Models to generate structured data conforming to Codable types.
    ///
    /// ## Example
    /// ```swift
    /// struct MovieReview: Codable, Sendable {
    ///     let title: String
    ///     let rating: Int
    /// }
    ///
    /// let provider = ARCIntelligence.generableProvider()
    /// let review: MovieReview = try await provider.generate(
    ///     MovieReview.self,
    ///     prompt: "Review the movie Inception",
    ///     configuration: .default
    /// )
    /// ```
    ///
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider() -> some GenerableProvider {
        logger.debug("Creating GenerableProvider (FoundationModels)")
        return FoundationModelsProvider(configuration: .default)
    }

    /// Create a generable provider with custom configuration.
    /// - Parameter configuration: Custom Foundation Models configuration.
    /// - Returns: A provider capable of guided generation.
    public static func generableProvider(
        configuration: FoundationModelsConfiguration
    ) -> some GenerableProvider {
        logger.debug("Creating GenerableProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
    }

    /// Create a tool provider for tool-assisted generation.
    ///
    /// Uses Foundation Models to generate responses that can call external tools.
    ///
    /// ## Example
    /// ```swift
    /// struct WeatherTool: IntelligenceTool {
    ///     let name = "getWeather"
    ///     let description = "Get weather for a city"
    ///
    ///     func execute(arguments: [String: Any]) async throws -> String {
    ///         return "72°F, Sunny"
    ///     }
    /// }
    ///
    /// let provider = ARCIntelligence.toolProvider()
    /// let response = try await provider.respond(
    ///     to: "What's the weather in Boston?",
    ///     tools: [WeatherTool()],
    ///     configuration: .default
    /// )
    /// ```
    ///
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider() -> some ToolProvider {
        logger.debug("Creating ToolProvider (FoundationModels)")
        return FoundationModelsProvider(configuration: .default)
    }

    /// Create a tool provider with custom configuration.
    /// - Parameter configuration: Custom Foundation Models configuration.
    /// - Returns: A provider capable of tool calling.
    public static func toolProvider(
        configuration: FoundationModelsConfiguration
    ) -> some ToolProvider {
        logger.debug("Creating ToolProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
    }

    /// Create a content tagging provider for text analysis.
    ///
    /// Uses Foundation Models to extract tags from text content.
    ///
    /// ## Example
    /// ```swift
    /// let provider = ARCIntelligence.contentTaggingProvider()
    /// let tags = try await provider.generateTags(
    ///     for: "I love hiking in the mountains!",
    ///     categories: [.topic, .emotion],
    ///     maxTags: 5
    /// )
    /// ```
    ///
    /// - Returns: A provider capable of content tagging.
    public static func contentTaggingProvider() -> some ContentTaggingProvider {
        logger.debug("Creating ContentTaggingProvider (FoundationModels)")
        return FoundationModelsProvider(configuration: .default)
    }

    /// Create a content tagging provider with custom configuration.
    /// - Parameter configuration: Custom Foundation Models configuration.
    /// - Returns: A provider capable of content tagging.
    public static func contentTaggingProvider(
        configuration: FoundationModelsConfiguration
    ) -> some ContentTaggingProvider {
        logger.debug("Creating ContentTaggingProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
    }
}
