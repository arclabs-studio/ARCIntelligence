//
//  GenerableProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Foundation

/// Protocol for providers that support guided generation of structured data.
///
/// Guided generation allows the model to produce output that conforms to a specific
/// Swift type, rather than raw strings. This provides strong guarantees about the
/// response format and eliminates manual parsing.
///
/// On Apple platforms (iOS 26+), this maps to the `@Generable` macro and
/// `LanguageModelSession.respond(to:generating:)` API.
///
/// ## Usage
/// ```swift
/// // Define a generable type (on iOS 26+, use @Generable macro)
/// struct MovieReview: Codable, Sendable {
///     let title: String
///     let rating: Int
///     let summary: String
/// }
///
/// // Generate structured data
/// let review: MovieReview = try await provider.generate(
///     MovieReview.self,
///     prompt: "Review the movie Inception",
///     configuration: .default
/// )
/// ```
public protocol GenerableProvider: IntelligenceProvider {
    /// Generate a structured response conforming to the specified type.
    ///
    /// - Parameters:
    ///   - type: The type to generate. Must conform to `Codable` and `Sendable`.
    ///   - prompt: The input prompt describing what to generate.
    ///   - configuration: Configuration for the generation.
    /// - Returns: An instance of the requested type populated by the model.
    /// - Throws: `IntelligenceError` if generation fails or the type cannot be produced.
    func generate<T: Codable & Sendable>(
        _ type: T.Type,
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> T

    /// Generate a structured response with a custom schema description.
    ///
    /// Use this when you need to provide additional context about how the
    /// type should be populated.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - prompt: The input prompt.
    ///   - schemaDescription: A description of what the schema represents.
    ///   - configuration: Configuration for the generation.
    /// - Returns: An instance of the requested type.
    /// - Throws: `IntelligenceError` if generation fails.
    func generate<T: Codable & Sendable>(
        _ type: T.Type,
        prompt: String,
        schemaDescription: String,
        configuration: CompletionConfiguration
    ) async throws -> T
}

// MARK: - Default Implementation

extension GenerableProvider {
    /// Default implementation that calls the schema-less variant.
    public func generate<T: Codable & Sendable>(
        _ type: T.Type,
        prompt: String,
        schemaDescription _: String,
        configuration: CompletionConfiguration
    ) async throws -> T {
        // Default: ignore schema description and use basic generation
        try await generate(type, prompt: prompt, configuration: configuration)
    }
}
