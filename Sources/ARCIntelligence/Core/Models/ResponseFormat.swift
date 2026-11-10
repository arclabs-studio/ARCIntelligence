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
/// let schema: JSONValue = .object([
///     "type": .string("ARRAY"),
///     "items": .object(["type": .string("STRING")])
/// ])
/// let config = CompletionConfiguration(responseFormat: .json(schema: schema))
/// ```
public enum ResponseFormat: Sendable, Equatable {
    /// Plain text response. This is the default behaviour.
    case text

    /// JSON response.
    ///
    /// When `schema` is provided, providers that support structured output
    /// will use it to constrain the response shape. The schema format is
    /// provider-specific (e.g. Gemini uses its own `Schema` type).
    /// Provider adapters are responsible for converting the value
    /// to whatever native schema type the provider expects.
    ///
    /// When `schema` is `nil`, the provider is instructed to return valid
    /// JSON but without any shape constraint.
    case json(schema: JSONValue? = nil)
}
