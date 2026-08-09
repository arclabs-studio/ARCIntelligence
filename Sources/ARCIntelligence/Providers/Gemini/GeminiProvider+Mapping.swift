//
//  GeminiProvider+Mapping.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

// MARK: - Mapping Helpers

extension GeminiProvider {
    // MARK: - Request Building

    /// Build an API request from a prompt and completion configuration.
    func buildRequest(prompt: String,
                      configuration: CompletionConfiguration,
                      tools: [GeminiFunctionDeclaration]? = nil,
                      toolConfig: GeminiToolConfig? = nil) -> GeminiGenerateContentRequest {
        let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions
        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens

        let systemInstruction = systemPrompt.map {
            GeminiContent(parts: [.text($0)])
        }

        let generationConfig = GeminiGenerationConfig(temperature: configuration.temperature,
                                                      maxOutputTokens: maxTokens,
                                                      topP: configuration.topP,
                                                      topK: nil,
                                                      stopSequences: configuration.stopSequences.isEmpty
                                                          ? nil
                                                          : configuration.stopSequences,
                                                      candidateCount: nil)

        return GeminiGenerateContentRequest(model: self.configuration.model.modelId,
                                            contents: [GeminiContent(role: "user", parts: [.text(prompt)])],
                                            systemInstruction: systemInstruction,
                                            generationConfig: generationConfig,
                                            tools: tools.map { [GeminiTool(functionDeclarations: $0)] },
                                            toolConfig: toolConfig)
    }

    /// Build an API request from a conversation history and a new message.
    func buildConversationRequest(conversation: Conversation,
                                  newMessage: Message,
                                  configuration: CompletionConfiguration,
                                  tools: [GeminiFunctionDeclaration]? = nil,
                                  toolConfig: GeminiToolConfig? = nil) -> GeminiGenerateContentRequest {
        var contents: [GeminiContent] = []
        contents.reserveCapacity(conversation.messages.count + 1)

        // Map conversation history (skip system messages — they go to systemInstruction)
        for message in conversation.messages {
            switch message.role {
            case .user:
                contents.append(GeminiContent(role: "user", parts: [.text(message.content)]))
            case .assistant:
                contents.append(GeminiContent(role: "model", parts: [.text(message.content)]))
            case .system:
                // System messages are handled via the `systemInstruction` field
                break
            }
        }

        // Append the new user message
        if newMessage.role == .user {
            contents.append(GeminiContent(role: "user", parts: [.text(newMessage.content)]))
        }

        // Use conversation's system prompt, then config, then provider default
        let systemPromptText = conversation.systemPrompt
            ?? configuration.systemPrompt
            ?? self.configuration.defaultInstructions

        let systemInstruction = systemPromptText.map {
            GeminiContent(parts: [.text($0)])
        }

        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens

        let generationConfig = GeminiGenerationConfig(temperature: configuration.temperature,
                                                      maxOutputTokens: maxTokens,
                                                      topP: configuration.topP,
                                                      topK: nil,
                                                      stopSequences: configuration.stopSequences.isEmpty
                                                          ? nil
                                                          : configuration.stopSequences,
                                                      candidateCount: nil)

        return GeminiGenerateContentRequest(model: self.configuration.model.modelId,
                                            contents: contents,
                                            systemInstruction: systemInstruction,
                                            generationConfig: generationConfig,
                                            tools: tools.map { [GeminiTool(functionDeclarations: $0)] },
                                            toolConfig: toolConfig)
    }

    // MARK: - Response Mapping

    /// Map an API response to an `IntelligenceResponse`.
    func mapResponse(_ response: GeminiGenerateContentResponse) -> IntelligenceResponse {
        let candidate = response.candidates?.first

        let textContent = candidate?.content?.parts
            .compactMap { part -> String? in
                if case let .text(text) = part {
                    return text
                }
                return nil
            }
            .joined() ?? ""

        let promptTokens = response.usageMetadata?.promptTokenCount ?? 0
        let outputTokens = response.usageMetadata?.candidatesTokenCount ?? 0
        let tokensUsed = response.usageMetadata?.totalTokenCount ?? (promptTokens + outputTokens)

        let finishReason = mapFinishReason(candidate?.finishReason)

        return IntelligenceResponse(content: textContent,
                                    tokensUsed: tokensUsed,
                                    finishReason: finishReason,
                                    metadata: ["model": response.modelVersion ?? configuration.model.modelId,
                                               "promptTokens": "\(promptTokens)",
                                               "outputTokens": "\(outputTokens)"])
    }

    /// Map a Gemini finish reason to `FinishReason`.
    func mapFinishReason(_ finishReason: String?) -> IntelligenceResponse.FinishReason {
        switch finishReason {
        case "STOP":
            .completed
        case "MAX_TOKENS":
            .maxTokens
        case "SAFETY", "RECITATION":
            .contentFilter
        default:
            .unknown
        }
    }

    // MARK: - Tool Schema Mapping

    /// Convert an `IntelligenceTool` to a `GeminiFunctionDeclaration`.
    func mapToolToDefinition(_ tool: any IntelligenceTool) -> GeminiFunctionDeclaration {
        let schema: GeminiSchema?

        if let toolSchema = tool.parametersSchema {
            var properties: [String: GeminiSchemaProperty] = [:]
            for param in toolSchema.parameters {
                properties[param.name] = GeminiSchemaProperty(type: param.type.rawValue,
                                                              description: param.description,
                                                              enumValues: param.enumValues)
            }

            schema = GeminiSchema(type: "object",
                                  properties: properties,
                                  required: toolSchema.required.isEmpty ? nil : toolSchema.required)
        } else {
            schema = GeminiSchema(type: "object")
        }

        return GeminiFunctionDeclaration(name: tool.name,
                                         description: tool.description,
                                         parameters: schema)
    }

    // MARK: - Function Call Extraction

    /// Represents a function call extracted from a response.
    struct ExtractedFunctionCall {
        let id: String?
        let name: String
        let args: [String: AnyCodableValue]
    }

    /// Extract function call parts from the first response candidate.
    func extractFunctionCalls(from response: GeminiGenerateContentResponse) -> [ExtractedFunctionCall] {
        response.candidates?.first?.content?.parts.compactMap { part -> ExtractedFunctionCall? in
            if case let .functionCall(call) = part {
                return ExtractedFunctionCall(id: call.id,
                                             name: call.name,
                                             args: call.args ?? [:])
            }
            return nil
        } ?? []
    }
}
