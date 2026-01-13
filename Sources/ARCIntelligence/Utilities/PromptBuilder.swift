//
//  PromptBuilder.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Utility for building well-formatted prompts for AI providers.
///
/// Helps construct prompts with proper structure, context, and formatting.
public struct PromptBuilder: Sendable {

    // MARK: - Properties

    private var components: [String] = []
    private let separator: String

    // MARK: - Initialization

    public init(separator: String = "\n\n") {
        self.separator = separator
    }

    // MARK: - Builder Methods

    /// Add a system instruction
    /// - Parameter instruction: The system instruction text
    /// - Returns: Updated builder instance
    public func withSystemInstruction(_ instruction: String) -> PromptBuilder {
        var builder = self
        builder.components.append("System: \(instruction)")
        return builder
    }

    /// Add a context section
    /// - Parameter context: The context text
    /// - Returns: Updated builder instance
    public func withContext(_ context: String) -> PromptBuilder {
        var builder = self
        builder.components.append("Context: \(context)")
        return builder
    }

    /// Add a user query
    /// - Parameter query: The user query text
    /// - Returns: Updated builder instance
    public func withQuery(_ query: String) -> PromptBuilder {
        var builder = self
        builder.components.append("Query: \(query)")
        return builder
    }

    /// Add a custom section
    /// - Parameters:
    ///   - label: Section label
    ///   - content: Section content
    /// - Returns: Updated builder instance
    public func withSection(label: String, content: String) -> PromptBuilder {
        var builder = self
        builder.components.append("\(label): \(content)")
        return builder
    }

    /// Add raw text
    /// - Parameter text: The raw text to add
    /// - Returns: Updated builder instance
    public func withText(_ text: String) -> PromptBuilder {
        var builder = self
        builder.components.append(text)
        return builder
    }

    /// Build the final prompt
    /// - Returns: The constructed prompt string
    public func build() -> String {
        components.joined(separator: separator)
    }

    // MARK: - Static Helpers

    /// Create a simple prompt from a query
    /// - Parameter query: The user query
    /// - Returns: Formatted prompt
    public static func simple(query: String) -> String {
        PromptBuilder()
            .withQuery(query)
            .build()
    }

    /// Create a context-aware prompt
    /// - Parameters:
    ///   - query: The user query
    ///   - context: The context information
    /// - Returns: Formatted prompt
    public static func withContext(query: String, context: String) -> String {
        PromptBuilder()
            .withContext(context)
            .withQuery(query)
            .build()
    }

    /// Create a system-instructed prompt
    /// - Parameters:
    ///   - query: The user query
    ///   - systemInstruction: The system instruction
    /// - Returns: Formatted prompt
    public static func withSystem(query: String, systemInstruction: String) -> String {
        PromptBuilder()
            .withSystemInstruction(systemInstruction)
            .withQuery(query)
            .build()
    }
}
