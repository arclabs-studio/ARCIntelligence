//
//  Embedding.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Vector representation of text for semantic search and similarity comparison.
public struct Embedding: Sendable, Equatable {

    // MARK: - Properties

    /// The embedding vector
    public let vector: [Float]

    /// The original text that was embedded
    public let text: String

    /// Dimension of the embedding vector
    public var dimension: Int {
        vector.count
    }

    // MARK: - Initialization

    public init(vector: [Float], text: String) {
        self.vector = vector
        self.text = text
    }

    // MARK: - Similarity

    /// Calculate cosine similarity between two embeddings
    /// - Parameter other: The other embedding to compare with
    /// - Returns: Similarity score (0.0 to 1.0)
    public func cosineSimilarity(to other: Embedding) -> Float {
        guard vector.count == other.vector.count else {
            return 0.0
        }

        let dotProduct = zip(vector, other.vector).reduce(0.0) { $0 + ($1.0 * $1.1) }
        let magnitude1 = sqrt(vector.reduce(0.0) { $0 + ($1 * $1) })
        let magnitude2 = sqrt(other.vector.reduce(0.0) { $0 + ($1 * $1) })

        guard magnitude1 > 0, magnitude2 > 0 else {
            return 0.0
        }

        return dotProduct / (magnitude1 * magnitude2)
    }
}
