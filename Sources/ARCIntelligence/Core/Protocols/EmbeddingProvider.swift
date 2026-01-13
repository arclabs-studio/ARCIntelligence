//
//  EmbeddingProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Protocol for providers that generate text embeddings for semantic search.
///
/// Embeddings are vector representations of text that capture semantic meaning,
/// enabling similarity comparisons and semantic search capabilities.
public protocol EmbeddingProvider: IntelligenceProvider {

    /// Generate an embedding vector for the given text
    /// - Parameter text: The input text
    /// - Returns: Vector representation of the text
    /// - Throws: `IntelligenceError` if generation fails
    func generateEmbedding(for text: String) async throws -> Embedding

    /// Calculate semantic similarity between two texts
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Similarity score (0.0 to 1.0)
    /// - Throws: `IntelligenceError` if calculation fails
    func similarity(between text1: String, and text2: String) async throws -> Float

    /// Generate embeddings for multiple texts in batch
    /// - Parameter texts: Array of input texts
    /// - Returns: Array of embeddings in the same order
    /// - Throws: `IntelligenceError` if generation fails
    func generateEmbeddings(for texts: [String]) async throws -> [Embedding]
}
