//
//  RecommendationEngine.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

/// Engine for generating AI-powered recommendations.
///
/// Uses a `RecommendationProvider` to analyze user context and generate
/// personalized suggestions. Supports any Codable context type for flexibility.
public final class RecommendationEngine: Sendable {
    // MARK: - Properties

    private let provider: RecommendationProvider
    private let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                   category: "RecommendationEngine")

    // MARK: - Initialization

    public init(provider: RecommendationProvider) {
        self.provider = provider
    }

    // MARK: - Public Methods

    /// Generate recommendations based on context
    /// - Parameters:
    ///   - context: User context (history, preferences, etc.)
    ///   - numberOfRecommendations: Number of recommendations to generate
    ///   - configuration: Recommendation configuration
    /// - Returns: Array of recommendations
    /// - Throws: `IntelligenceError` if generation fails
    public func recommend(basedOn context: some Codable & Sendable,
                          numberOfRecommendations: Int = 5,
                          configuration: RecommendationConfiguration = .default) async throws -> [Recommendation] {
        logger.debug("Generating recommendations", metadata: [
            "requestedCount": .public("\(numberOfRecommendations)"),
            "contextType": .public("\(type(of: context))")
        ])

        guard numberOfRecommendations > 0 else {
            logger.warning("Invalid recommendation request: count must be > 0")
            throw IntelligenceError.invalidRequest("Count must be greater than 0")
        }

        let recommendations = try await provider.generateRecommendations(for: context,
                                                                         count: numberOfRecommendations,
                                                                         configuration: configuration)

        logger.info("Generated recommendations", metadata: ["resultCount": .public("\(recommendations.count)")])

        return recommendations
    }
}
