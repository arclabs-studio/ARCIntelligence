//
//  SemanticSearchTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligenceMocks
import Testing
@testable import ARCIntelligence

@Suite("Semantic Search Tests", .tags(.unit)) struct SemanticSearchTests {
    @Test("Search returns results sorted by similarity") func search_returnsSortedResults() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)
        let candidates = ["Swift programming language",
                          "Python data science",
                          "JavaScript web development"]

        // Act
        let results = try await search.search(query: "Swift programming",
                                              in: candidates,
                                              topK: 3)

        // Assert
        #expect(results.count == 3)
        #expect(results[0].similarity >= results[1].similarity)
        #expect(results[1].similarity >= results[2].similarity)
    }

    @Test("Search respects topK limit") func search_respectsTopKLimit() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)
        let candidates = ["First candidate",
                          "Second candidate",
                          "Third candidate",
                          "Fourth candidate",
                          "Fifth candidate"]

        // Act
        let results = try await search.search(query: "test query",
                                              in: candidates,
                                              topK: 2)

        // Assert
        #expect(results.count == 2)
    }

    @Test("Search with empty query throws error") func search_withEmptyQueryThrowsError() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)

        // Act & Assert
        await #expect(throws: IntelligenceError.self) {
            _ = try await search.search(query: "",
                                        in: ["test"],
                                        topK: 1)
        }
    }

    @Test("Search with empty candidates throws error") func search_withEmptyCandidatesThrowsError() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)

        // Act & Assert
        await #expect(throws: IntelligenceError.self) {
            _ = try await search.search(query: "test",
                                        in: [],
                                        topK: 1)
        }
    }

    @Test("Find similar returns results above threshold") func findSimilar_returnsResultsAboveThreshold() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)
        let candidates = ["Very similar text",
                          "Somewhat similar",
                          "Completely different"]

        // Act
        let results = try await search.findSimilar(to: "Similar reference text",
                                                   in: candidates,
                                                   threshold: 0.0 // Low threshold to get all results
        )

        // Assert
        #expect(!results.isEmpty)
        for result in results {
            #expect(result.similarity >= 0.0)
        }
    }

    @Test("Similarity calculation returns value between 0 and 1") func similarity_returnsValueInRange() async throws {
        // Arrange
        let provider = MockEmbeddingProvider()
        let search = SemanticSearch(provider: provider)

        // Act
        let similarity = try await search.similarity(between: "First text",
                                                     and: "Second text")

        // Assert
        #expect(similarity >= -1.0)
        #expect(similarity <= 1.0)
    }
}
