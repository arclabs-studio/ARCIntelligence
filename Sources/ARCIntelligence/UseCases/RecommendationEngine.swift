//
//  RecommendationEngine.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Engine for generating AI-powered recommendations.
///
/// Uses a `RecommendationProvider` to analyze user context and generate
/// personalized suggestions. Supports any Codable context type for flexibility.
public final class RecommendationEngine: Sendable {

    // MARK: - Properties

    private let provider: RecommendationProvider

    // MARK: - Initialization

    public init(provider: RecommendationProvider) {
        self.provider = provider
    }

    // MARK: - Public Methods

    /// Generate recommendations based on context
    /// - Parameters:
    ///   - context: User context (history, preferences, etc.)
    ///   - count: Number of recommendations to generate
    ///   - configuration: Recommendation configuration
    /// - Returns: Array of recommendations
    /// - Throws: `IntelligenceError` if generation fails
    public func recommend<T: Codable & Sendable>(
        basedOn context: T,
        count: Int = 5,
        configuration: RecommendationConfiguration = .default
    ) async throws -> [Recommendation] {
        guard count > 0 else {
            throw IntelligenceError.invalidRequest("Count must be greater than 0")
        }

        return try await provider.generateRecommendations(
            for: context,
            count: count,
            configuration: configuration
        )
    }
}
