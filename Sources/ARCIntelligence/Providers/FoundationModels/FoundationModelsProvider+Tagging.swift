//
//  FoundationModelsProvider+Tagging.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCLogger
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - ContentTaggingProvider Conformance

extension FoundationModelsProvider: ContentTaggingProvider {
    /// Generate content tags for the given text.
    ///
    /// On iOS 26+, this uses Apple's Foundation Models to analyze
    /// content and generate semantically consistent tags.
    ///
    /// - Parameters:
    ///   - text: The text to analyze.
    ///   - categories: Categories of tags to generate.
    ///   - maxTags: Maximum number of tags per category.
    /// - Returns: Array of content tags.
    /// - Throws: `IntelligenceError` if tagging fails.
    public func generateTags(for text: String,
                             categories: [TagCategory],
                             maxTags: Int) async throws -> [ContentTag] {
        logger.debug("Starting content tagging", metadata: ["textLength": .public("\(text.count)"),
                                                            "categories": .public(categories.map(\.rawValue)
                                                                .joined(separator: ", ")),
                                                            "maxTags": .public("\(maxTags)")])

        guard !text.isEmpty else {
            throw IntelligenceError.invalidRequest("Text cannot be empty")
        }

        let availability = await checkAvailability()
        guard availability.isAvailable else {
            logger.warning("Provider unavailable for content tagging")
            if let error = availability.toError() {
                throw error
            }
            throw IntelligenceError.providerUnavailable
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return try await performContentTagging(text: text,
                                                   categories: categories,
                                                   maxTags: maxTags)
        }
        #endif

        throw IntelligenceError.providerUnavailable
    }

    // MARK: - Private Implementation

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *) private func performContentTagging(text: String,
                                                                                          categories: [TagCategory],
                                                                                          maxTags: Int) async throws
    -> [ContentTag] {
        var allTags: [ContentTag] = []

        for category in categories {
            let tags = try await generateTagsForCategory(text: text,
                                                         category: category,
                                                         maxTags: maxTags)
            allTags.append(contentsOf: tags)
        }

        logger.info("Content tagging successful", metadata: ["totalTags": .public("\(allTags.count)")])

        return allTags
    }

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *) private func generateTagsForCategory(text: String,
                                                                                            category: TagCategory,
                                                                                            maxTags: Int) async throws
    -> [ContentTag] {
        do {
            let session = LanguageModelSession(instructions: """
            You are a content tagger. Extract \(category.rawValue)s from the given text.
            Return only comma-separated lowercase tags, nothing else.
            Maximum \(maxTags) tags.
            """)

            let prompt = "Extract \(category.rawValue)s from: \(text)"
            let response = try await session.respond(to: prompt)

            // Parse tags from response
            let tagStrings = response.content
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(maxTags)

            return tagStrings.map { tagValue in
                ContentTag(value: tagValue,
                           category: category,
                           confidence: 1.0)
            }
        } catch {
            throw mapFoundationModelsError(error)
        }
    }
    #endif
}
