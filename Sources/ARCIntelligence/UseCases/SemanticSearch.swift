//
//  SemanticSearch.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Engine for semantic search using embeddings.
///
/// Uses an `EmbeddingProvider` to generate vector representations of text
/// and perform similarity-based search.
public final class SemanticSearch: Sendable {

    // MARK: - Properties

    private let provider: EmbeddingProvider

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
        guard !query.isEmpty else {
            throw IntelligenceError.invalidRequest("Query cannot be empty")
        }

        guard !candidates.isEmpty else {
            throw IntelligenceError.invalidRequest("Candidates array cannot be empty")
        }

        guard topK > 0 else {
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
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map { $0 }
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
        guard !reference.isEmpty else {
            throw IntelligenceError.invalidRequest("Reference text cannot be empty")
        }

        guard !candidates.isEmpty else {
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
        return results.sorted { $0.similarity > $1.similarity }
    }

    /// Calculate semantic similarity between two texts
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Similarity score (0.0 to 1.0)
    /// - Throws: `IntelligenceError` if calculation fails
    public func similarity(between text1: String, and text2: String) async throws -> Float {
        guard !text1.isEmpty, !text2.isEmpty else {
            throw IntelligenceError.invalidRequest("Texts cannot be empty")
        }

        return try await provider.similarity(between: text1, and: text2)
    }
}
