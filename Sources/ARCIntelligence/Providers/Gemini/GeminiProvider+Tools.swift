//
//  GeminiProvider+Tools.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import ARCLogger
import Foundation

// MARK: - ToolProvider Conformance

extension GeminiProvider: ToolProvider {
    /// Generate a response using the provided tools.
    ///
    /// Implements the Gemini function calling loop:
    /// 1. Send request with function declarations
    /// 2. If the model returns `functionCall` parts, execute each tool locally
    /// 3. Send function results back as `functionResponse` parts in a user turn
    /// 4. Repeat until the model returns a text-only response or max rounds exceeded
    ///
    /// - Parameters:
    ///   - prompt: The input prompt.
    ///   - tools: Available tools for the model to use.
    ///   - configuration: Generation configuration.
    /// - Returns: Response and tool call records.
    /// - Throws: `IntelligenceError` if generation fails.
    public func respondWithToolCalls(to prompt: String,
                                     tools: [any IntelligenceTool],
                                     configuration: CompletionConfiguration) async throws
        -> (response: IntelligenceResponse,
            toolCalls: [ToolCallRecord]) {
        logger.debug("Starting tool-assisted generation", metadata: ["promptLength": .public("\(prompt.count)"),
                                                                     "toolCount": .public("\(tools.count)")])

        let context = GeminiToolCallingContext(toolDeclarations: tools.map { mapToolToDefinition($0) },
                                               toolsByName: Dictionary(uniqueKeysWithValues: tools
                                                   .map { ($0.name, $0) }),
                                               systemPrompt: configuration.systemPrompt ?? self.configuration
                                                   .defaultInstructions,
                                               maxTokens: configuration.maxTokens ?? self.configuration
                                                   .defaultMaxTokens,
                                               configuration: configuration)

        let (response, allToolCalls) = try await executeToolLoop(context: context, prompt: prompt)

        let intelligenceResponse = mapResponse(response)

        logger.info("Tool-assisted generation successful",
                    metadata: ["totalToolCalls": .public("\(allToolCalls.count)"),
                               "tokensUsed": .public("\(intelligenceResponse.tokensUsed)")])

        return (intelligenceResponse, allToolCalls)
    }
}

// MARK: - Private Tool Calling Helpers

private struct GeminiToolCallingContext {
    let toolDeclarations: [GeminiFunctionDeclaration]
    let toolsByName: [String: any IntelligenceTool]
    let systemPrompt: String?
    let maxTokens: Int
    let configuration: CompletionConfiguration
}

extension GeminiProvider {
    private func executeToolLoop(context: GeminiToolCallingContext,
                                 prompt: String) async throws -> (GeminiGenerateContentResponse, [ToolCallRecord]) {
        var contents: [GeminiContent] = [GeminiContent(role: "user", parts: [.text(prompt)])]
        var allToolCalls: [ToolCallRecord] = []

        for round in 0 ..< configuration.maxToolRounds {
            let request = buildToolRequest(context: context, contents: contents)
            let response = try await apiClient.generateContent(request)
            let functionCalls = extractFunctionCalls(from: response)

            if functionCalls.isEmpty {
                return (response, allToolCalls)
            }

            // Append the model's function call turn
            if let modelContent = response.candidates?.first?.content {
                contents.append(modelContent)
            }

            // Execute tools and collect function response parts
            let (responseParts, calls) = try await executePendingFunctions(functionCalls, context: context)
            allToolCalls.append(contentsOf: calls)

            // Append tool results as a user turn
            contents.append(GeminiContent(role: "user", parts: responseParts))

            logger.debug("Tool round completed", metadata: ["round": .public("\(round + 1)"),
                                                            "toolCalls": .public("\(functionCalls.count)")])
        }

        logger.warning("Max tool rounds exceeded")
        throw IntelligenceError.requestFailed("Exceeded maximum tool calling rounds (\(configuration.maxToolRounds))")
    }

    private func buildToolRequest(context: GeminiToolCallingContext,
                                  contents: [GeminiContent]) -> GeminiGenerateContentRequest {
        let systemInstruction = context.systemPrompt.map { GeminiContent(parts: [.text($0)]) }

        let generationConfig = GeminiGenerationConfig(temperature: context.configuration.temperature,
                                                      maxOutputTokens: context.maxTokens,
                                                      topP: context.configuration.topP,
                                                      topK: nil,
                                                      stopSequences: context.configuration.stopSequences.isEmpty
                                                          ? nil
                                                          : context.configuration.stopSequences,
                                                      candidateCount: nil)

        let toolConfig = GeminiToolConfig(functionCallingConfig: GeminiFunctionCallingConfig(mode: "AUTO",
                                                                                             allowedFunctionNames: nil))

        return GeminiGenerateContentRequest(model: configuration.model.modelId,
                                            contents: contents,
                                            systemInstruction: systemInstruction,
                                            generationConfig: generationConfig,
                                            tools: [GeminiTool(functionDeclarations: context.toolDeclarations)],
                                            toolConfig: toolConfig)
    }

    private func executePendingFunctions(_ calls: [ExtractedFunctionCall],
                                         context: GeminiToolCallingContext) async throws -> ([GeminiPart],
                                                                                             [ToolCallRecord]) {
        var responseParts: [GeminiPart] = []
        responseParts.reserveCapacity(calls.count)
        var records: [ToolCallRecord] = []
        records.reserveCapacity(calls.count)

        for call in calls {
            let (part, record) = await executeSingleFunction(call, context: context)
            responseParts.append(part)
            records.append(record)
        }

        return (responseParts, records)
    }

    private func executeSingleFunction(_ call: ExtractedFunctionCall,
                                       context: GeminiToolCallingContext) async -> (GeminiPart, ToolCallRecord) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let arguments = call.args.mapValues { $0.toToolArgumentValue }
        let stringArguments = ToolArgumentValue.toStringDictionary(arguments)

        let output: String

        if let tool = context.toolsByName[call.name] {
            do {
                output = try await tool.execute(arguments: arguments)
            } catch {
                let errorOutput = "Error: \(error.localizedDescription)"
                logger.warning("Tool execution failed", metadata: ["tool": .public(call.name),
                                                                   "error": .public(error.localizedDescription)])
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let record = ToolCallRecord(toolName: call.name,
                                            arguments: stringArguments,
                                            output: errorOutput,
                                            duration: duration)
                let errorResponse = GeminiFunctionResponse(name: call.name,
                                                           id: call.id,
                                                           response: ["result": .string(errorOutput)])
                let part = GeminiPart.functionResponse(errorResponse)
                return (part, record)
            }
        } else {
            output = "Error: Unknown tool '\(call.name)'"
            logger.warning("Unknown tool requested", metadata: ["tool": .public(call.name)])
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let record = ToolCallRecord(toolName: call.name,
                                    arguments: stringArguments,
                                    output: output,
                                    duration: duration)
        let part = GeminiPart.functionResponse(GeminiFunctionResponse(name: call.name,
                                                                      id: call.id,
                                                                      response: ["result": .string(output)]))

        return (part, record)
    }
}
