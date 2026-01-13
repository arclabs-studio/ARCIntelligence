//
//  SemanticSearch.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

/// Engine for semantic search using embeddings.
///
/// Uses an `EmbeddingProvider` to generate vector representations of text
/// and perform similarity-based search.
public final class SemanticSearch: Sendable {

    // MARK: - Properties

    private let provider: EmbeddingProvider
    private let logger = ARCLogger(
        subsystem: "com.arclabs.intelligence",
        category: "SemanticSearch"
    )

    // MARK: - Initialization

    public init(provider: EmbeddingProvider) {
        self.provider = provider
    }

    // MARK: - Public Methods

    /// Search for the most similar texts to a query
    /// - Parameters:
    ///   - query: The search query
    ///   - candidates: Array of candidate texts to search
    ///   - topK: Number of top results to return
    /// - Returns: Array of tuples containing (text, similarity score)
    /// - Throws: `IntelligenceError` if search fails
    public func search(
        query: String,
        in candidates: [String],
        topK: Int = 5
    ) async throws -> [(text: String, similarity: Float)] {
        logger.debug("Starting semantic search", metadata: [
            "queryLength": .public("\(query.count)"),
            "candidateCount": .public("\(candidates.count)"),
            "topK": .public("\(topK)")
        ])

        guard !query.isEmpty else {
            logger.warning("Search failed: empty query")
            throw IntelligenceError.invalidRequest("Query cannot be empty")
        }

        guard !candidates.isEmpty else {
            logger.warning("Search failed: empty candidates")
            throw IntelligenceError.invalidRequest("Candidates array cannot be empty")
        }

        guard topK > 0 else {
            logger.warning("Search failed: invalid topK value")
            throw IntelligenceError.invalidRequest("topK must be greater than 0")
        }

        // Generate embeddings
        let queryEmbedding = try await provider.generateEmbedding(for: query)
        let candidateEmbeddings = try await provider.generateEmbeddings(for: candidates)

        // Calculate similarities
        var results: [(text: String, similarity: Float)] = []
        for (index, candidateEmbedding) in candidateEmbeddings.enumerated() {
            let similarity = queryEmbedding.cosineSimilarity(to: candidateEmbedding)
            results.append((text: candidates[index], similarity: similarity))
        }

        // Sort by similarity (descending) and take top K
        let sortedResults = results
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map { $0 }

        logger.info("Semantic search completed", metadata: [
            "resultCount": .public("\(sortedResults.count)")
        ])

        return sortedResults
    }

    /// Find texts similar to a reference text
    /// - Parameters:
    ///   - reference: The reference text
    ///   - candidates: Array of candidate texts to compare
    ///   - threshold: Minimum similarity threshold (0.0 to 1.0)
    /// - Returns: Array of tuples containing (text, similarity score) above threshold
    /// - Throws: `IntelligenceError` if search fails
    public func findSimilar(
        to reference: String,
        in candidates: [String],
        threshold: Float = 0.7
    ) async throws -> [(text: String, similarity: Float)] {
        logger.debug("Finding similar texts", metadata: [
            "referenceLength": .public("\(reference.count)"),
            "candidateCount": .public("\(candidates.count)"),
            "threshold": .public("\(threshold)")
        ])

        guard !reference.isEmpty else {
            logger.warning("Find similar failed: empty reference")
            throw IntelligenceError.invalidRequest("Reference text cannot be empty")
        }

        guard !candidates.isEmpty else {
            logger.warning("Find similar failed: empty candidates")
            throw IntelligenceError.invalidRequest("Candidates array cannot be empty")
        }

        let validThreshold = max(0.0, min(1.0, threshold))

        // Generate embeddings
        let referenceEmbedding = try await provider.generateEmbedding(for: reference)
        let candidateEmbeddings = try await provider.generateEmbeddings(for: candidates)

        // Calculate similarities and filter by threshold
        var results: [(text: String, similarity: Float)] = []
        for (index, candidateEmbedding) in candidateEmbeddings.enumerated() {
            let similarity = referenceEmbedding.cosineSimilarity(to: candidateEmbedding)
            if similarity >= validThreshold {
                results.append((text: candidates[index], similarity: similarity))
            }
        }

        // Sort by similarity (descending)
        let sortedResults = results.sorted { $0.similarity > $1.similarity }

        logger.info("Find similar completed", metadata: [
            "matchCount": .public("\(sortedResults.count)"),
            "aboveThreshold": .public("\(sortedResults.count)")
        ])

        return sortedResults
    }

    /// Calculate semantic similarity between two texts
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Similarity score (0.0 to 1.0)
    /// - Throws: `IntelligenceError` if calculation fails
    public func similarity(between text1: String, and text2: String) async throws -> Float {
        logger.debug("Calculating similarity", metadata: [
            "text1Length": .public("\(text1.count)"),
            "text2Length": .public("\(text2.count)")
        ])

        guard !text1.isEmpty, !text2.isEmpty else {
            logger.warning("Similarity calculation failed: empty text")
            throw IntelligenceError.invalidRequest("Texts cannot be empty")
        }

        let result = try await provider.similarity(between: text1, and: text2)

        logger.info("Similarity calculated", metadata: [
            "similarity": .public("\(result)")
        ])

        return result
    }
}
