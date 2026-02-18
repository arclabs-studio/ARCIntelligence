//
//  ARCIntelligence+UseCases.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - Use Case Factories

extension ARCIntelligence {
    /// Create a conversational assistant with a provider.
    /// - Parameter provider: The conversation provider to use.
    /// - Returns: Configured conversational assistant.
    public static func conversationalAssistant(provider: ConversationProvider) -> ConversationalAssistant {
        logger.debug("Creating ConversationalAssistant")
        return ConversationalAssistant(provider: provider)
    }

    /// Create a recommendation engine with a provider.
    /// - Parameter provider: The recommendation provider to use.
    /// - Returns: Configured recommendation engine.
    public static func recommendationEngine(provider: RecommendationProvider) -> RecommendationEngine {
        logger.debug("Creating RecommendationEngine")
        return RecommendationEngine(provider: provider)
    }

    /// Create a semantic search engine with a provider.
    /// - Parameter provider: The embedding provider to use.
    /// - Returns: Configured semantic search engine.
    public static func semanticSearch(provider: EmbeddingProvider) -> SemanticSearch {
        logger.debug("Creating SemanticSearch")
        return SemanticSearch(provider: provider)
    }
}
