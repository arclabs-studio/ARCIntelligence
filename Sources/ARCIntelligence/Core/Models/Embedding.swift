//
//  Embedding.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Accelerate
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
        guard vector.count == other.vector.count, !vector.isEmpty else {
            return 0.0
        }

        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0

        vDSP_dotpr(vector, 1, other.vector, 1, &dotProduct, vDSP_Length(vector.count))
        vDSP_dotpr(vector, 1, vector, 1, &magnitude1, vDSP_Length(vector.count))
        vDSP_dotpr(other.vector, 1, other.vector, 1, &magnitude2, vDSP_Length(other.vector.count))

        magnitude1 = sqrt(magnitude1)
        magnitude2 = sqrt(magnitude2)

        guard magnitude1 > 0, magnitude2 > 0 else {
            return 0.0
        }

        return dotProduct / (magnitude1 * magnitude2)
    }
}
