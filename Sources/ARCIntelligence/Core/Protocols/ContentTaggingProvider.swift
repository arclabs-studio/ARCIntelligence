//
//  ContentTaggingProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Foundation

/// Protocol for providers that support content tagging.
///
/// Content tagging uses a specialized model to identify topics, actions,
/// objects, and emotions in text. Tags are semantically consistent and
/// use one to a few lowercase words.
///
/// On Apple platforms (iOS 26+), this maps to `SystemLanguageModel.UseCase.contentTagging`.
///
/// ## Usage
/// ```swift
/// let tags = try await provider.generateTags(
///     for: "I love hiking in the mountains on sunny days!",
///     categories: [.topic, .emotion, .action]
/// )
/// // tags: ["hiking", "mountains", "joy", "outdoor activity"]
/// ```
public protocol ContentTaggingProvider: IntelligenceProvider {
    /// Generate tags for the given text.
    ///
    /// - Parameters:
    ///   - text: The text to analyze.
    ///   - categories: Categories of tags to generate.
    ///   - maxTags: Maximum number of tags to return per category.
    /// - Returns: Array of generated tags.
    /// - Throws: `IntelligenceError` if tagging fails.
    func generateTags(
        for text: String,
        categories: [TagCategory],
        maxTags: Int
    ) async throws -> [ContentTag]

    /// Generate tags for multiple texts in batch.
    ///
    /// - Parameters:
    ///   - texts: Array of texts to analyze.
    ///   - categories: Categories of tags to generate.
    ///   - maxTagsPerText: Maximum tags per text.
    /// - Returns: Array of tag arrays, one per input text.
    /// - Throws: `IntelligenceError` if tagging fails.
    func generateTagsBatch(
        for texts: [String],
        categories: [TagCategory],
        maxTagsPerText: Int
    ) async throws -> [[ContentTag]]
}

// MARK: - Tag Category

/// Categories of content tags.
public enum TagCategory: String, Sendable, Equatable, CaseIterable {
    /// Topics discussed in the content (e.g., "technology", "cooking").
    case topic

    /// Actions being performed (e.g., "running", "writing").
    case action

    /// Objects mentioned (e.g., "laptop", "coffee").
    case object

    /// Emotions expressed (e.g., "happy", "frustrated").
    case emotion
}

// MARK: - Content Tag

/// A tag generated from content analysis.
public struct ContentTag: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier for the tag.
    public let id: UUID

    /// The tag value (lowercase, 1-3 words).
    public let value: String

    /// Category of the tag.
    public let category: TagCategory

    /// Confidence score (0.0-1.0).
    public let confidence: Float

    public init(
        id: UUID = UUID(),
        value: String,
        category: TagCategory,
        confidence: Float = 1.0
    ) {
        self.id = id
        self.value = value.lowercased()
        self.category = category
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

// MARK: - Codable Conformance for TagCategory

extension TagCategory: Codable {}

// MARK: - Default Implementations

extension ContentTaggingProvider {
    /// Default implementation using all categories.
    public func generateTags(
        for text: String,
        maxTags: Int = 5
    ) async throws -> [ContentTag] {
        try await generateTags(
            for: text,
            categories: TagCategory.allCases,
            maxTags: maxTags
        )
    }

    /// Default batch implementation that processes texts sequentially.
    public func generateTagsBatch(
        for texts: [String],
        categories: [TagCategory],
        maxTagsPerText: Int
    ) async throws -> [[ContentTag]] {
        var results: [[ContentTag]] = []
        for text in texts {
            let tags = try await generateTags(
                for: text,
                categories: categories,
                maxTags: maxTagsPerText
            )
            results.append(tags)
        }
        return results
    }
}
