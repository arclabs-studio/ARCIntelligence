//
//  RecommendationEngineTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Testing

import ARCIntelligenceMocks
@testable import ARCIntelligence

/// Test context for recommendation engine
struct TestUserContext: Codable, Sendable {
    let interests: [String]
    let history: [String]
}

@Suite("Recommendation Engine Tests")
struct RecommendationEngineTests {
    @Test("Recommend returns requested number of recommendations")
    func recommend_returnsRequestedCount() async throws {
        // Arrange
        let provider = MockRecommendationProvider()
        let engine = RecommendationEngine(provider: provider)
        let context = TestUserContext(
            interests: ["Swift", "iOS"],
            history: ["tutorial1"]
        )

        // Act
        let recommendations = try await engine.recommend(
            basedOn: context,
            numberOfRecommendations: 3,
            configuration: .default
        )

        // Assert
        #expect(recommendations.count == 3)
    }

    @Test("Recommend with zero count throws error")
    func recommend_withZeroCountThrowsError() async throws {
        // Arrange
        let provider = MockRecommendationProvider()
        let engine = RecommendationEngine(provider: provider)
        let context = TestUserContext(interests: [], history: [])

        // Act & Assert
        await #expect(throws: IntelligenceError.self) {
            _ = try await engine.recommend(
                basedOn: context,
                numberOfRecommendations: 0,
                configuration: .default
            )
        }
    }

    @Test("Recommend with negative count throws error")
    func recommend_withNegativeCountThrowsError() async throws {
        // Arrange
        let provider = MockRecommendationProvider()
        let engine = RecommendationEngine(provider: provider)
        let context = TestUserContext(interests: [], history: [])

        // Act & Assert
        await #expect(throws: IntelligenceError.self) {
            _ = try await engine.recommend(
                basedOn: context,
                numberOfRecommendations: -1,
                configuration: .default
            )
        }
    }

    @Test("Recommendations have valid confidence scores")
    func recommend_hasValidConfidenceScores() async throws {
        // Arrange
        let provider = MockRecommendationProvider()
        let engine = RecommendationEngine(provider: provider)
        let context = TestUserContext(
            interests: ["AI", "Machine Learning"],
            history: []
        )

        // Act
        let recommendations = try await engine.recommend(
            basedOn: context,
            numberOfRecommendations: 5,
            configuration: .default
        )

        // Assert
        for recommendation in recommendations {
            #expect(recommendation.confidence >= 0.0)
            #expect(recommendation.confidence <= 1.0)
        }
    }

    @Test("Recommend with failing provider throws error")
    func recommend_withFailingProviderThrowsError() async throws {
        // Arrange
        let provider = MockRecommendationProvider(shouldFail: true)
        let engine = RecommendationEngine(provider: provider)
        let context = TestUserContext(interests: [], history: [])

        // Act & Assert
        await #expect(throws: IntelligenceError.self) {
            _ = try await engine.recommend(
                basedOn: context,
                numberOfRecommendations: 3,
                configuration: .default
            )
        }
    }
}
