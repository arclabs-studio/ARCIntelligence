//
//  RecommendationProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Protocol for providers that generate recommendations based on context.
///
/// Used for suggesting content, products, or actions based on user history
/// and preferences. The context can be any Codable type representing the
/// recommendation input data.
public protocol RecommendationProvider: IntelligenceProvider {
    /// Generate recommendations based on typed context
    /// - Parameters:
    ///   - context: The context data (user history, preferences, etc.)
    ///   - count: Number of recommendations to generate
    ///   - configuration: Recommendation-specific configuration
    /// - Returns: Array of recommendations
    /// - Throws: `IntelligenceError` if generation fails
    func generateRecommendations(for context: some Codable & Sendable,
                                 count: Int,
                                 configuration: RecommendationConfiguration) async throws -> [Recommendation]
}
