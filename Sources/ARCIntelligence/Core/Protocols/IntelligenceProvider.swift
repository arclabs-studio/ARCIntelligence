//
//  IntelligenceProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Base protocol for all AI providers in ARCIntelligence.
///
/// Providers can be Apple Foundation Models, OpenAI, Anthropic, or custom implementations.
/// All providers must be thread-safe and support async operations.
public protocol IntelligenceProvider: Sendable {

    // MARK: - Identification

    /// Unique identifier for the provider (e.g., "com.arclabs.intelligence.foundation")
    var id: String { get }

    /// Human-readable name for display purposes
    var displayName: String { get }

    /// Provider version or model identifier
    var version: String { get }

    // MARK: - Availability

    /// Check if the provider is available on the current device/environment
    /// - Returns: True if the provider can be used
    func isAvailable() async -> Bool

    // MARK: - Completion

    /// Generate a completion for a single prompt
    /// - Parameters:
    ///   - prompt: The input text prompt
    ///   - configuration: Completion configuration (temperature, max tokens, etc.)
    /// - Returns: The generated response
    /// - Throws: `IntelligenceError` if the request fails
    func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse

    /// Stream completion tokens as they are generated
    /// - Parameters:
    ///   - prompt: The input text prompt
    ///   - configuration: Completion configuration
    /// - Returns: An async stream of response chunks
    func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error>
}
