//
//  ARCIntelligence+FoundationModels.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - Foundation Models Factory Methods

extension ARCIntelligence {
    /// Create a Foundation Models provider with default configuration.
    /// - Returns: Configured Foundation Models provider.
    public static func foundationModels() -> FoundationModelsProvider {
        logger.debug("Creating FoundationModelsProvider with default configuration")
        return FoundationModelsProvider(configuration: .default)
    }

    /// Create a Foundation Models provider with custom configuration.
    /// - Parameter configuration: Custom configuration.
    /// - Returns: Configured Foundation Models provider.
    public static func foundationModels(configuration: FoundationModelsConfiguration) -> FoundationModelsProvider {
        logger.debug("Creating FoundationModelsProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
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
    public static func generableProvider(configuration: FoundationModelsConfiguration) -> some GenerableProvider {
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
    ///     func execute(arguments: [String: ToolArgumentValue]) async throws -> String {
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
    public static func toolProvider(configuration: FoundationModelsConfiguration) -> some ToolProvider {
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
    public static func contentTaggingProvider(configuration: FoundationModelsConfiguration)
    -> some ContentTaggingProvider {
        logger.debug("Creating ContentTaggingProvider with custom configuration")
        return FoundationModelsProvider(configuration: configuration)
    }
}
