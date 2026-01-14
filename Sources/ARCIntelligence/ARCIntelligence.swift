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
///
/// ### Providers
/// - ``FoundationModelsProvider``
/// - ``FoundationModelsConfiguration``
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
}
