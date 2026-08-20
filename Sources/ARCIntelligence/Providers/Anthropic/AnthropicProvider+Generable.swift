//
//  AnthropicProvider+Generable.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import ARCLogger
import Foundation

// MARK: - GenerableProvider Conformance

extension AnthropicProvider: GenerableProvider {
    /// Generate a structured response using forced tool_use.
    ///
    /// Internally creates a tool whose input schema matches the JSON structure
    /// of `T`, forces the model to call it via `tool_choice`, and decodes the
    /// tool input arguments as `T`.
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

        let response = try await apiClient.sendMessage(request)
        let toolUseBlocks = extractToolUseBlocks(from: response)

        guard let toolUse = toolUseBlocks.first else {
            throw IntelligenceError
                .responseParseFailed("Model did not produce a tool_use block for structured generation")
        }

        guard case let .string(jsonString) = toolUse.input["json_output"] else {
            return try decodeFromInput(toolUse.input, type: type)
        }

        return try decodeJSON(jsonString, type: type)
    }

    private func buildGenerationRequest(_ type: (some Any).Type,
                                        prompt: String,
                                        schemaDescription: String?,
                                        configuration: CompletionConfiguration) -> AnthropicMessageRequest {
        let toolName = "generate_\(String(describing: type).lowercased())"
        let description = schemaDescription
            ?? "Generate a structured \(String(describing: type)) response."

        let jsonOutputDescription = "The complete JSON object as a string conforming to the requested type."
        let jsonOutputProperty = AnthropicSchemaProperty(type: "string",
                                                         description: jsonOutputDescription,
                                                         enumValues: nil)

        let inputSchema = AnthropicInputSchema(type: "object",
                                               properties: ["json_output": jsonOutputProperty],
                                               required: ["json_output"])
        let toolDefinition = AnthropicToolDefinition(name: toolName,
                                                     description: description,
                                                     inputSchema: inputSchema)

        let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions
        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens
        let enhancedPrompt = """
        \(prompt)

        You MUST call the \(toolName) tool with the result as valid JSON in the json_output field.
        """

        return AnthropicMessageRequest(model: self.configuration.model.modelId,
                                       messages: [AnthropicAPIMessage(role: "user", text: enhancedPrompt)],
                                       maxTokens: maxTokens,
                                       system: systemPrompt,
                                       temperature: Double(configuration.temperature),
                                       topP: configuration.topP.map { Double($0) },
                                       stopSequences: nil,
                                       stream: false,
                                       tools: [toolDefinition],
                                       toolChoice: .tool(name: toolName))
    }

    private func decodeJSON<T: Codable>(_ jsonString: String,
                                        type: T.Type) throws -> T {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw IntelligenceError.responseParseFailed("Unable to convert tool output to data")
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

    /// Fallback: try to decode `T` directly from the tool input dictionary.
    private func decodeFromInput<T: Codable>(_ input: [String: AnyCodableValue],
                                             type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(input)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw IntelligenceError
                .responseParseFailed("Failed to decode tool input as \(type): \(error.localizedDescription)")
        }
    }
}
