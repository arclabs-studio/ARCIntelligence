//
//  MockContentTaggingProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `ContentTaggingProvider` for testing.
///
/// Allows configuring canned tag responses for testing content tagging workflows.
///
/// ## Usage
/// ```swift
/// // Simple usage with predefined tags
/// let mock = MockContentTaggingProvider(
///     tagsToReturn: [
///         ContentTag(value: "technology", category: .topic),
///         ContentTag(value: "happy", category: .emotion)
///     ]
/// )
///
/// // With category-specific tags
/// let mock = MockContentTaggingProvider(
///     tagsByCategory: [
///         .topic: ["technology", "programming"],
///         .emotion: ["excited", "curious"]
///     ]
/// )
/// ```
public final class MockContentTaggingProvider: IntelligenceProvider, ContentTaggingProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.tagging"
    public let displayName = "Mock Content Tagging Provider"
    public let version = "1.0"

    private let tagsToReturn: [ContentTag]
    private let tagsByCategory: [TagCategory: [String]]?
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval
    private let errorToThrow: IntelligenceError?

    // MARK: - Initialization

    /// Create a mock provider with explicit tags to return.
    ///
    /// - Parameters:
    ///   - tagsToReturn: Tags to return for any request.
    ///   - shouldFail: Whether to simulate failure.
    ///   - simulatedDelay: Delay before returning response.
    ///   - errorToThrow: Specific error to throw when failing.
    public init(tagsToReturn: [ContentTag] = [],
                shouldFail: Bool = false,
                simulatedDelay: TimeInterval = 0.1,
                errorToThrow: IntelligenceError? = nil) {
        self.tagsToReturn = tagsToReturn
        tagsByCategory = nil
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
        self.errorToThrow = errorToThrow
    }

    /// Create a mock provider with category-specific tag values.
    ///
    /// - Parameters:
    ///   - tagsByCategory: Dictionary mapping categories to tag value strings.
    ///   - shouldFail: Whether to simulate failure.
    ///   - simulatedDelay: Delay before returning response.
    ///   - errorToThrow: Specific error to throw when failing.
    public init(tagsByCategory: [TagCategory: [String]],
                shouldFail: Bool = false,
                simulatedDelay: TimeInterval = 0.1,
                errorToThrow: IntelligenceError? = nil) {
        tagsToReturn = []
        self.tagsByCategory = tagsByCategory
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
        self.errorToThrow = errorToThrow
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt _: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock failure")
        }

        let tagDescriptions = tagsToReturn.map { "\($0.category.rawValue): \($0.value)" }
        let content = tagDescriptions.joined(separator: ", ")

        return IntelligenceResponse(content: content,
                                    tokensUsed: content.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt _: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: errorToThrow ?? IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                let tagDescriptions = tagsToReturn.map { "\($0.category.rawValue): \($0.value)" }
                let content = tagDescriptions.joined(separator: ", ")
                continuation.yield(content)
                continuation.finish()
            }
        }
    }

    // MARK: - ContentTaggingProvider

    public func generateTags(for _: String,
                             categories: [TagCategory],
                             maxTags: Int) async throws -> [ContentTag] {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock tagging failure")
        }

        // If we have category-specific tags, generate from those
        if let tagsByCategory {
            var result: [ContentTag] = []
            for category in categories {
                if let values = tagsByCategory[category] {
                    let tagsForCategory = values.prefix(maxTags).map { value in
                        ContentTag(value: value,
                                   category: category,
                                   confidence: Float.random(in: 0.7 ... 1.0))
                    }
                    result.append(contentsOf: tagsForCategory)
                }
            }
            return Array(result.prefix(maxTags * categories.count))
        }

        // Otherwise filter and return from tagsToReturn
        let filteredTags = tagsToReturn.filter { categories.contains($0.category) }
        return Array(filteredTags.prefix(maxTags * categories.count))
    }
}

// MARK: - Convenience Factory Methods

extension MockContentTaggingProvider {
    /// Create a mock provider that returns common test tags.
    ///
    /// Provides a standard set of tags useful for testing:
    /// - Topics: "technology", "programming"
    /// - Actions: "coding", "learning"
    /// - Objects: "computer", "software"
    /// - Emotions: "curious", "focused"
    public static func standard() -> MockContentTaggingProvider {
        MockContentTaggingProvider(tagsByCategory: [
            .topic: ["technology", "programming"],
            .action: ["coding", "learning"],
            .object: ["computer", "software"],
            .emotion: ["curious", "focused"]
        ])
    }

    /// Create a mock provider that always fails.
    ///
    /// - Parameter error: The error to throw. Defaults to a generic request failure.
    public static func failing(with error: IntelligenceError = .requestFailed("Mock tagging failure"))
    -> MockContentTaggingProvider {
        MockContentTaggingProvider(shouldFail: true,
                                   errorToThrow: error)
    }
}
