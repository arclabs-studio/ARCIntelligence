//
//  GrokProvider+Generable.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import ARCLogger
import Foundation

// MARK: - GenerableProvider Conformance

extension GrokProvider: GenerableProvider {
    /// Generate a structured response using forced function calling.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - prompt: The input prompt.
    ///   - configuration: Generation configuration.
    /// - Returns: An instance of the requested type.
    /// - Throws: `IntelligenceError` if generation or decoding fails.
    public func generate<T: Codable & Sendable>(_ type: T.Type,
                                                prompt: String,
                                                configuration: CompletionConfiguration) async throws -> T {
        try await performGeneration(type, prompt: prompt, schemaDescription: nil, configuration: configuration)
    }

    /// Generate a structured response with a custom schema description.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - prompt: The input prompt.
    ///   - schemaDescription: A description of what the schema represents.
    ///   - configuration: Generation configuration.
    /// - Returns: An instance of the requested type.
    /// - Throws: `IntelligenceError` if generation or decoding fails.
    public func generate<T: Codable & Sendable>(_ type: T.Type,
                                                prompt: String,
                                                schemaDescription: String,
                                                configuration: CompletionConfiguration) async throws -> T {
        try await performGeneration(type,
                                    prompt: prompt,
                                    schemaDescription: schemaDescription,
                                    configuration: configuration)
    }

    // MARK: - Private Implementation

    private func performGeneration<T: Codable & Sendable>(_ type: T.Type,
                                                          prompt: String,
                                                          schemaDescription: String?,
                                                          configuration: CompletionConfiguration) async throws -> T {
        logger.debug("Starting structured generation", metadata: [
            "type": .public(String(describing: type)),
            "promptLength": .public("\(prompt.count)")
        ])

        let request = OpenAICompatibleMapping
            .buildGenerationRequest(type,
                                    prompt: prompt,
                                    schemaDescription: schemaDescription,
                                    modelId: self.configuration.model.modelId,
                                    defaultInstructions: self.configuration.defaultInstructions,
                                    defaultMaxTokens: self.configuration.defaultMaxTokens,
                                    configuration: configuration)

        let response = try await apiClient.sendChatCompletion(request)
        let toolCalls = extractToolCalls(from: response)

        guard let toolCall = toolCalls.first else {
            throw IntelligenceError
                .responseParseFailed("Model did not produce a tool call for structured generation")
        }

        if let jsonOutput = try OpenAICompatibleMapping.extractJsonOutput(from: toolCall.arguments) {
            let result = try OpenAICompatibleMapping.decodeJSON(jsonOutput, type: type)
            logger.info("Structured generation successful", metadata: ["type": .public(String(describing: type))])
            return result
        }

        do {
            let result = try OpenAICompatibleMapping.decodeJSON(toolCall.arguments, type: type)
            logger.info("Structured generation successful (direct decode)",
                        metadata: ["type": .public(String(describing: type))])
            return result
        } catch {
            logger.error("Failed to decode structured response", metadata: [
                "type": .public(String(describing: type)),
                "error": .public(error.localizedDescription)
            ])
            throw error
        }
    }
}
