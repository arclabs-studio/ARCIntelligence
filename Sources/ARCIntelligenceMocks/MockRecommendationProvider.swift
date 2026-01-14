//
//  MockRecommendationProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `RecommendationProvider` for testing.
///
/// Returns configurable canned recommendations for testing recommendation workflows.
/// Allows configuring failure scenarios and simulated delays.
public final class MockRecommendationProvider: RecommendationProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.recommendation"
    public let displayName = "Mock Recommendation Provider"
    public let version = "1.0"

    private let recommendations: [Recommendation]
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval

    // MARK: - Initialization

    /// Creates a mock recommendation provider.
    /// - Parameters:
    ///   - recommendations: Canned recommendations to return (default: sample recommendations)
    ///   - shouldFail: Whether operations should throw errors (default: false)
    ///   - simulatedDelay: Delay before returning results (default: 0.1 seconds)
    public init(
        recommendations: [Recommendation]? = nil,
        shouldFail: Bool = false,
        simulatedDelay: TimeInterval = 0.1
    ) {
        self.recommendations = recommendations ?? Self.defaultRecommendations
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(
        prompt: String,
        configuration _: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw IntelligenceError.requestFailed("Mock recommendation provider failure")
        }

        return IntelligenceResponse(
            content: "Mock completion for recommendation provider",
            tokensUsed: prompt.count / 4,
            finishReason: .completed
        )
    }

    public func streamComplete(
        prompt _: String,
        configuration _: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                let response = "Mock streaming response"
                for char in response {
                    try? await Task.sleep(for: .milliseconds(10))
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - RecommendationProvider

    public func generateRecommendations(
        for _: some Codable & Sendable,
        count: Int,
        configuration _: RecommendationConfiguration
    ) async throws -> [Recommendation] {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw IntelligenceError.requestFailed("Mock recommendation generation failed")
        }

        // Return requested number of recommendations
        let availableCount = min(count, recommendations.count)
        return Array(recommendations.prefix(availableCount))
    }

    // MARK: - Default Recommendations

    private static let defaultRecommendations: [Recommendation] = [
        Recommendation(
            title: "SwiftUI Essentials",
            description: "Learn the fundamentals of SwiftUI development",
            confidence: 0.95,
            category: "Learning",
            metadata: ["type": "course"]
        ),
        Recommendation(
            title: "Async/Await Patterns",
            description: "Master Swift concurrency with async/await",
            confidence: 0.88,
            category: "Learning",
            metadata: ["type": "tutorial"]
        ),
        Recommendation(
            title: "Clean Architecture",
            description: "Design scalable iOS applications",
            confidence: 0.82,
            category: "Architecture",
            metadata: ["type": "guide"]
        ),
        Recommendation(
            title: "Testing Best Practices",
            description: "Write effective unit and integration tests",
            confidence: 0.75,
            category: "Testing",
            metadata: ["type": "documentation"]
        ),
        Recommendation(
            title: "Performance Optimization",
            description: "Optimize your app for speed and efficiency",
            confidence: 0.70,
            category: "Performance",
            metadata: ["type": "guide"]
        )
    ]
}
