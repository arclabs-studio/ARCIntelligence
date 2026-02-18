//
//  MockEmbeddingProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `EmbeddingProvider` for testing.
///
/// Generates deterministic embeddings based on text hash for consistent testing.
/// Allows configuring failure scenarios and simulated delays.
public final class MockEmbeddingProvider: EmbeddingProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.embedding"
    public let displayName = "Mock Embedding Provider"
    public let version = "1.0"

    private let embeddingDimension: Int
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval

    // MARK: - Initialization

    /// Creates a mock embedding provider.
    /// - Parameters:
    ///   - embeddingDimension: Dimension of generated embedding vectors (default: 128)
    ///   - shouldFail: Whether operations should throw errors (default: false)
    ///   - simulatedDelay: Delay before returning results (default: 0.05 seconds)
    public init(embeddingDimension: Int = 128,
                shouldFail: Bool = false,
                simulatedDelay: TimeInterval = 0.05) {
        self.embeddingDimension = embeddingDimension
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw IntelligenceError.requestFailed("Mock embedding provider failure")
        }

        return IntelligenceResponse(content: "Mock completion for embedding provider",
                                    tokensUsed: prompt.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt _: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                let response = "Mock streaming response"
                for char in response {
                    try await Task.sleep(for: .milliseconds(10))
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - EmbeddingProvider

    public func generateEmbedding(for text: String) async throws -> Embedding {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw IntelligenceError.requestFailed("Mock embedding generation failed")
        }

        let vector = generateDeterministicVector(for: text)
        return Embedding(vector: vector, text: text)
    }

    public func similarity(between text1: String, and text2: String) async throws -> Float {
        let embedding1 = try await generateEmbedding(for: text1)
        let embedding2 = try await generateEmbedding(for: text2)
        return embedding1.cosineSimilarity(to: embedding2)
    }

    public func generateEmbeddings(for texts: [String]) async throws -> [Embedding] {
        var embeddings: [Embedding] = []
        embeddings.reserveCapacity(texts.count)
        for text in texts {
            let embedding = try await generateEmbedding(for: text)
            embeddings.append(embedding)
        }
        return embeddings
    }

    // MARK: - Private Methods

    /// Generates a deterministic vector based on text content.
    /// Uses a stable hash (sum of UTF-8 bytes) instead of hashValue which varies between runs.
    private func generateDeterministicVector(for text: String) -> [Float] {
        var vector = [Float](repeating: 0.0, count: embeddingDimension)

        // Use sum of UTF-8 bytes for deterministic seeding (hashValue changes between runs)
        let stableHash = text.utf8.reduce(0) { $0 &+ UInt64($1) }
        var seed = stableHash &* 6_364_136_223_846_793_005 &+ 1

        for index in 0 ..< embeddingDimension {
            // Simple linear congruential generator for deterministic values
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let value = Float(seed % 10000) / 10000.0 - 0.5
            vector[index] = value
        }

        // Normalize the vector
        let magnitude = sqrt(vector.reduce(0.0) { $0 + $1 * $1 })
        if magnitude > 0 {
            vector = vector.map { $0 / magnitude }
        }

        return vector
    }
}
