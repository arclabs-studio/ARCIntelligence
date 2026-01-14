//
//  EmbeddingTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Testing

@testable import ARCIntelligence

@Suite("Embedding Tests")
struct EmbeddingTests {
    @Test("Embedding initializes with correct values")
    func init_setsValuesCorrectly() {
        // Arrange & Act
        let vector: [Float] = [0.1, 0.2, 0.3, 0.4]
        let embedding = Embedding(vector: vector, text: "test text")

        // Assert
        #expect(embedding.vector == vector)
        #expect(embedding.text == "test text")
        #expect(embedding.dimension == 4)
    }

    @Test("Cosine similarity of identical vectors is 1.0")
    func cosineSimilarity_identicalVectorsReturnsOne() {
        // Arrange
        let vector: [Float] = [1.0, 0.0, 0.0]
        let embedding1 = Embedding(vector: vector, text: "text1")
        let embedding2 = Embedding(vector: vector, text: "text2")

        // Act
        let similarity = embedding1.cosineSimilarity(to: embedding2)

        // Assert
        #expect(abs(similarity - 1.0) < 0.0001)
    }

    @Test("Cosine similarity of orthogonal vectors is 0.0")
    func cosineSimilarity_orthogonalVectorsReturnsZero() {
        // Arrange
        let embedding1 = Embedding(vector: [1.0, 0.0, 0.0], text: "text1")
        let embedding2 = Embedding(vector: [0.0, 1.0, 0.0], text: "text2")

        // Act
        let similarity = embedding1.cosineSimilarity(to: embedding2)

        // Assert
        #expect(abs(similarity) < 0.0001)
    }

    @Test("Cosine similarity of different dimension vectors is 0.0")
    func cosineSimilarity_differentDimensionsReturnsZero() {
        // Arrange
        let embedding1 = Embedding(vector: [1.0, 0.0, 0.0], text: "text1")
        let embedding2 = Embedding(vector: [1.0, 0.0], text: "text2")

        // Act
        let similarity = embedding1.cosineSimilarity(to: embedding2)

        // Assert
        #expect(similarity == 0.0)
    }

    @Test("Cosine similarity with zero magnitude vector is 0.0")
    func cosineSimilarity_zeroMagnitudeReturnsZero() {
        // Arrange
        let embedding1 = Embedding(vector: [0.0, 0.0, 0.0], text: "text1")
        let embedding2 = Embedding(vector: [1.0, 0.0, 0.0], text: "text2")

        // Act
        let similarity = embedding1.cosineSimilarity(to: embedding2)

        // Assert
        #expect(similarity == 0.0)
    }
}
