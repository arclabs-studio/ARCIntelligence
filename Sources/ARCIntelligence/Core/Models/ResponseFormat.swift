//
//  ResponseFormat.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/04/2026.
//

import Foundation

/// Response format configuration for AI completions.
///
/// Controls whether the provider returns plain text or structured JSON.
/// When `.json(schema:)` is used, providers that support structured output
/// will constrain their response to match the provided schema.
///
/// Provider adapters are responsible for mapping this value to the
/// provider-specific structured output mechanism. Providers that do not
/// support structured output silently fall back to plain-text generation.
///
/// ## Usage
///
/// ```swift
/// // Request plain text (default)
/// let config = CompletionConfiguration(responseFormat: .text)
///
/// // Request JSON without a schema
/// let config = CompletionConfiguration(responseFormat: .json())
///
/// // Request JSON constrained by a schema
/// let schema: [String: Any] = ["type": "ARRAY", "items": [...]]
/// let config = CompletionConfiguration(responseFormat: .json(schema: schema))
/// ```
/// `@unchecked Sendable` because `[String: Any]` in the `.json` associated value
/// cannot be automatically verified as Sendable. The schema dictionary is set
/// once at creation and never mutated, making this safe.
public enum ResponseFormat: @unchecked Sendable, Equatable {
    /// Plain text response. This is the default behaviour.
    case text

    /// JSON response.
    ///
    /// When `schema` is provided, providers that support structured output
    /// will use it to constrain the response shape. The schema format is
    /// provider-specific (e.g. Gemini uses its own `Schema` type).
    /// Provider adapters are responsible for converting the dictionary
    /// to whatever native schema type the provider expects.
    ///
    /// When `schema` is `nil`, the provider is instructed to return valid
    /// JSON but without any shape constraint.
    case json(schema: [String: Any]? = nil)

    // MARK: Equatable

    /// Schema equality is best-effort: two `.json` cases are considered equal
    /// regardless of schema content, because `[String: Any]` is not `Equatable`.
    public static func == (lhs: ResponseFormat, rhs: ResponseFormat) -> Bool {
        switch (lhs, rhs) {
        case (.text, .text): true
        case (.json, .json): true
        default: false
        }
    }
}
