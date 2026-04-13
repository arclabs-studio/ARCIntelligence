//
//  GeminiProvider+Generable.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import ARCLogger
import Foundation

// MARK: - GenerableProvider Conformance

extension GeminiProvider: GenerableProvider {
    /// Generate a structured response using forced function calling.
    ///
    /// Internally creates a function declaration whose parameter schema wraps
    /// the JSON for `T`, forces the model to call it via `toolConfig` with mode
    /// `ANY`, and decodes the function call arguments as `T`.
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
        logger.debug("Starting structured generation", metadata: ["type": .public(String(describing: type)),
                                                                  "promptLength": .public("\(prompt.count)")])

        let request = buildGenerationRequest(type,
                                             prompt: prompt,
                                             schemaDescription: schemaDescription,
                                             configuration: configuration)

        let response = try await apiClient.generateContent(request)
        let functionCalls = extractFunctionCalls(from: response)

        guard let call = functionCalls.first else {
            throw IntelligenceError
                .responseParseFailed("Model did not produce a function call for structured generation")
        }

        guard case let .string(jsonString) = call.args["json_output"] else {
            return try decodeFromArgs(call.args, type: type)
        }

        return try decodeJSON(jsonString, type: type)
    }

    private func buildGenerationRequest(_ type: (some Any).Type,
                                        prompt: String,
                                        schemaDescription: String?,
                                        configuration: CompletionConfiguration) -> GeminiGenerateContentRequest {
        let functionName = "generate_\(String(describing: type).lowercased())"
        let description = schemaDescription
            ?? "Generate a structured \(String(describing: type)) response."

        let jsonOutputDescription = "The complete JSON object as a string conforming to the requested type."
        let jsonOutputProperty = GeminiSchemaProperty(type: "string",
                                                      description: jsonOutputDescription,
                                                      enumValues: nil)

        let schema = GeminiSchema(type: "object",
                                  properties: ["json_output": jsonOutputProperty],
                                  required: ["json_output"])

        let functionDeclaration = GeminiFunctionDeclaration(name: functionName,
                                                            description: description,
                                                            parameters: schema)

        let callingConfig = GeminiFunctionCallingConfig(mode: "ANY", allowedFunctionNames: [functionName])
        let toolConfig = GeminiToolConfig(functionCallingConfig: callingConfig)

        let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions
        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens

        let systemInstruction = systemPrompt.map { GeminiContent(parts: [.text($0)]) }

        let enhancedPrompt = """
        \(prompt)

        You MUST call the \(functionName) function with the result as valid JSON in the json_output field.
        """

        let generationConfig = GeminiGenerationConfig(temperature: configuration.temperature,
                                                      maxOutputTokens: maxTokens,
                                                      topP: configuration.topP,
                                                      topK: nil,
                                                      stopSequences: nil,
                                                      candidateCount: nil)

        return GeminiGenerateContentRequest(model: self.configuration.model.modelId,
                                            contents: [GeminiContent(role: "user", parts: [.text(enhancedPrompt)])],
                                            systemInstruction: systemInstruction,
                                            generationConfig: generationConfig,
                                            tools: [GeminiTool(functionDeclarations: [functionDeclaration])],
                                            toolConfig: toolConfig)
    }

    private func decodeJSON<T: Codable>(_ jsonString: String,
                                        type: T.Type) throws -> T {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw IntelligenceError.responseParseFailed("Unable to convert function output to data")
        }

        do {
            let result = try JSONDecoder().decode(type, from: jsonData)
            logger.info("Structured generation successful", metadata: ["type": .public(String(describing: type))])
            return result
        } catch {
            logger.error("Failed to decode structured response", metadata: ["type": .public(String(describing: type)),
                                                                            "error": .public(error
                                                                                .localizedDescription)])
            throw IntelligenceError
                .responseParseFailed("Failed to decode response as \(type): \(error.localizedDescription)")
        }
    }

    /// Fallback: try to decode `T` directly from the function call args dictionary.
    private func decodeFromArgs<T: Codable>(_ args: [String: AnyCodableValue],
                                            type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(args)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw IntelligenceError
                .responseParseFailed("Failed to decode function args as \(type): \(error.localizedDescription)")
        }
    }
}
