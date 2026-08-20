//
//  RecommendationConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Configuration for recommendation generation.
public struct RecommendationConfiguration: Sendable, Equatable {
    // MARK: - Properties

    /// Diversity factor (0.0 = similar, 1.0 = diverse)
    public let diversity: Float

    /// Number of context items to consider
    public let contextWindow: Int

    /// Custom filters (implementation-specific)
    public let filters: [String: String]

    // MARK: - Initialization

    public init(diversity: Float = 0.7,
                contextWindow: Int = 10,
                filters: [String: String] = [:]) {
        self.diversity = max(0.0, min(1.0, diversity))
        self.contextWindow = max(1, contextWindow)
        self.filters = filters
    }

    // MARK: - Presets

    /// Default configuration
    public static let `default` = RecommendationConfiguration()

    /// High diversity configuration
    public static let diverse = RecommendationConfiguration(diversity: 0.9,
                                                            contextWindow: 15)

    /// High similarity configuration
    public static let similar = RecommendationConfiguration(diversity: 0.3,
                                                            contextWindow: 5)
}
