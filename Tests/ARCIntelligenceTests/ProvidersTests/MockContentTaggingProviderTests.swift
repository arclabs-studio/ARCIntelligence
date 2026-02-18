//
//  MockContentTaggingProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Testing
@testable import ARCIntelligence
@testable import ARCIntelligenceMocks

@Suite("Mock Content Tagging Provider Tests", .tags(.unit))
struct MockContentTaggingProviderTests {
    // MARK: - Availability Tests

    @Test("Mock content tagging provider is always available")
    func isAvailable() async {
        let provider = MockContentTaggingProvider()
        let available = await provider.isAvailable()
        #expect(available)
    }

    // MARK: - Tag Generation Tests

    @Test("Generate tags returns configured tags")
    func generateTagsReturnsConfiguredTags() async throws {
        let expectedTags = [
            ContentTag(value: "technology", category: .topic),
            ContentTag(value: "happy", category: .emotion)
        ]
        let provider = MockContentTaggingProvider(tagsToReturn: expectedTags)

        let tags = try await provider.generateTags(for: "I love coding!",
                                                   categories: [.topic, .emotion],
                                                   maxTags: 5)

        #expect(tags.count == 2)
        #expect(tags.contains { $0.value == "technology" })
        #expect(tags.contains { $0.value == "happy" })
    }

    @Test("Generate tags filters by category")
    func generateTagsFiltersByCategory() async throws {
        let allTags = [
            ContentTag(value: "technology", category: .topic),
            ContentTag(value: "coding", category: .action),
            ContentTag(value: "happy", category: .emotion)
        ]
        let provider = MockContentTaggingProvider(tagsToReturn: allTags)

        let tags = try await provider.generateTags(for: "Test",
                                                   categories: [.topic],
                                                   maxTags: 5)

        #expect(tags.count == 1)
        #expect(tags[0].value == "technology")
        #expect(tags[0].category == .topic)
    }

    @Test("Generate tags respects maxTags limit")
    func generateTagsRespectsMaxLimit() async throws {
        let manyTags = (1 ... 10).map { index in
            ContentTag(value: "tag\(index)", category: .topic)
        }
        let provider = MockContentTaggingProvider(tagsToReturn: manyTags)

        let tags = try await provider.generateTags(for: "Test",
                                                   categories: [.topic],
                                                   maxTags: 3)

        #expect(tags.count == 3)
    }

    // MARK: - Category-Based Initialization Tests

    @Test("Generate tags from category dictionary")
    func generateTagsFromCategoryDictionary() async throws {
        let provider = MockContentTaggingProvider(tagsByCategory: [
            .topic: ["swift", "programming"],
            .emotion: ["excited"]
        ])

        let tags = try await provider.generateTags(for: "Learning Swift",
                                                   categories: [.topic, .emotion],
                                                   maxTags: 5)

        #expect(tags.count == 3)
        #expect(tags.count(where: { $0.category == .topic }) == 2)
        #expect(tags.count(where: { $0.category == .emotion }) == 1)
    }

    @Test("Category-based tags have confidence scores")
    func categoryBasedTagsHaveConfidence() async throws {
        let provider = MockContentTaggingProvider(tagsByCategory: [.topic: ["test"]])

        let tags = try await provider.generateTags(for: "Test",
                                                   categories: [.topic],
                                                   maxTags: 1)

        #expect(tags.count == 1)
        #expect(tags[0].confidence >= 0.7)
        #expect(tags[0].confidence <= 1.0)
    }

    // MARK: - Factory Method Tests

    @Test("Standard factory returns common tags")
    func standardFactoryReturnsCommonTags() async throws {
        let provider = MockContentTaggingProvider.standard()

        let tags = try await provider.generateTags(for: "Test",
                                                   categories: TagCategory.allCases,
                                                   maxTags: 10)

        #expect(!tags.isEmpty)
        #expect(tags.contains { $0.value == "technology" })
        #expect(tags.contains { $0.value == "coding" })
    }

    @Test("Failing factory throws error")
    func failingFactoryThrowsError() async {
        let provider = MockContentTaggingProvider.failing()

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.generateTags(for: "Test",
                                                categories: [.topic],
                                                maxTags: 5)
        }
    }

    @Test("Failing factory throws custom error")
    func failingFactoryThrowsCustomError() async {
        let customError = IntelligenceError.modelNotReady
        let provider = MockContentTaggingProvider.failing(with: customError)

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.generateTags(for: "Test",
                                                categories: [TagCategory.topic],
                                                maxTags: 5)
        }
    }

    // MARK: - Batch Tests

    @Test("Generate tags batch processes multiple texts")
    func generateTagsBatchProcessesMultipleTexts() async throws {
        let provider = MockContentTaggingProvider(tagsByCategory: [.topic: ["test"]])

        let results = try await provider.generateTagsBatch(for: ["Text 1", "Text 2", "Text 3"],
                                                           categories: [.topic],
                                                           maxTagsPerText: 2)

        #expect(results.count == 3)
        #expect(results.allSatisfy { !$0.isEmpty })
    }

    // MARK: - Error Tests

    @Test("Provider throws error when shouldFail is true")
    func providerThrowsErrorWhenFailing() async {
        let provider = MockContentTaggingProvider(shouldFail: true)

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.generateTags(for: "Test",
                                                categories: [.topic],
                                                maxTags: 5)
        }
    }

    @Test("Provider throws configured error")
    func providerThrowsConfiguredError() async {
        let expectedError = IntelligenceError.contextWindowExceeded(used: 1000, limit: 500)
        let provider = MockContentTaggingProvider(shouldFail: true,
                                                  errorToThrow: expectedError)

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.generateTags(for: "Test",
                                                categories: [TagCategory.topic],
                                                maxTags: 5)
        }
    }

    // MARK: - Complete Tests

    @Test("Complete returns tag descriptions as content")
    func completeReturnsTagDescriptions() async throws {
        let tags = [ContentTag(value: "tech", category: .topic)]
        let provider = MockContentTaggingProvider(tagsToReturn: tags)

        let response = try await provider.complete(prompt: "Test",
                                                   configuration: .default)

        #expect(response.content.contains("topic"))
        #expect(response.content.contains("tech"))
    }
}
