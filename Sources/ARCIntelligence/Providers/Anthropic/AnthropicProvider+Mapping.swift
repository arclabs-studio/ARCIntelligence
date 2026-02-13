//
//  AnthropicProvider+Mapping.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation

// MARK: - Mapping Helpers

extension AnthropicProvider {
    // MARK: - Request Building

    /// Build an API request from a prompt and configuration.
    func buildRequest(
        prompt: String,
        configuration: CompletionConfiguration,
        stream: Bool = false,
        tools: [AnthropicToolDefinition]? = nil,
        toolChoice: AnthropicToolChoice? = nil
    ) -> AnthropicMessageRequest {
        let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions

        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens

        return AnthropicMessageRequest(
            model: self.configuration.model.modelId,
            messages: [AnthropicAPIMessage(role: "user", text: prompt)],
            maxTokens: maxTokens,
            system: systemPrompt,
            temperature: Double(configuration.temperature),
            topP: configuration.topP.map { Double($0) },
            stopSequences: configuration.stopSequences.isEmpty ? nil : configuration.stopSequences,
            stream: stream,
            tools: tools,
            toolChoice: toolChoice
        )
    }

    /// Build an API request from a conversation.
    func buildConversationRequest(
        conversation: Conversation,
        newMessage: Message,
        configuration: CompletionConfiguration,
        stream: Bool = false
    ) -> AnthropicMessageRequest {
        var apiMessages: [AnthropicAPIMessage] = []

        // Map conversation history (skip system messages, they go to the system field)
        for message in conversation.messages {
            switch message.role {
            case .user:
                apiMessages.append(AnthropicAPIMessage(role: "user", text: message.content))
            case .assistant:
                apiMessages.append(AnthropicAPIMessage(role: "assistant", text: message.content))
            case .system:
                // System messages are handled via the `system` field, skip them here
                break
            }
        }

        // Add the new message
        if newMessage.role == .user {
            apiMessages.append(AnthropicAPIMessage(role: "user", text: newMessage.content))
        }

        // Use conversation's system prompt, or config default
        let systemPrompt = conversation.systemPrompt
            ?? configuration.systemPrompt
            ?? self.configuration.defaultInstructions

        let maxTokens = configuration.maxTokens ?? self.configuration.defaultMaxTokens

        return AnthropicMessageRequest(
            model: self.configuration.model.modelId,
            messages: apiMessages,
            maxTokens: maxTokens,
            system: systemPrompt,
            temperature: Double(configuration.temperature),
            topP: configuration.topP.map { Double($0) },
            stopSequences: configuration.stopSequences.isEmpty ? nil : configuration.stopSequences,
            stream: stream,
            tools: nil,
            toolChoice: nil
        )
    }

    // MARK: - Response Mapping

    /// Map an API response to an `IntelligenceResponse`.
    func mapResponse(_ response: AnthropicMessageResponse) -> IntelligenceResponse {
        let textContent = response.content
            .compactMap { block -> String? in
                if case let .text(text) = block {
                    return text
                }
                return nil
            }
            .joined()

        let tokensUsed = response.usage.inputTokens + response.usage.outputTokens
        let finishReason = mapStopReason(response.stopReason)

        return IntelligenceResponse(
            content: textContent,
            tokensUsed: tokensUsed,
            finishReason: finishReason,
            metadata: [
                "model": response.model,
                "inputTokens": "\(response.usage.inputTokens)",
                "outputTokens": "\(response.usage.outputTokens)"
            ]
        )
    }

    /// Map an API stop reason to `FinishReason`.
    func mapStopReason(_ stopReason: String?) -> IntelligenceResponse.FinishReason {
        switch stopReason {
        case "end_turn":
            .completed
        case "max_tokens":
            .maxTokens
        case "stop_sequence":
            .stopSequence
        case "tool_use":
            .completed
        default:
            .unknown
        }
    }

    // MARK: - Tool Schema Mapping

    /// Convert an `IntelligenceTool` to an `AnthropicToolDefinition`.
    func mapToolToDefinition(_ tool: any IntelligenceTool) -> AnthropicToolDefinition {
        let inputSchema: AnthropicInputSchema

        if let schema = tool.parametersSchema {
            var properties: [String: AnthropicSchemaProperty] = [:]
            for param in schema.parameters {
                properties[param.name] = AnthropicSchemaProperty(
                    type: param.type.rawValue,
                    description: param.description,
                    enumValues: param.enumValues
                )
            }

            inputSchema = AnthropicInputSchema(
                type: "object",
                properties: properties,
                required: schema.required.isEmpty ? nil : schema.required
            )
        } else {
            inputSchema = AnthropicInputSchema(type: "object")
        }

        return AnthropicToolDefinition(
            name: tool.name,
            description: tool.description,
            inputSchema: inputSchema
        )
    }

    // MARK: - Tool Use Extraction

    /// Represents a tool use block extracted from an API response.
    struct ExtractedToolUse {
        let id: String
        let name: String
        let input: [String: AnyCodableValue]
    }

    /// Extract tool use blocks from a response.
    func extractToolUseBlocks(from response: AnthropicMessageResponse) -> [ExtractedToolUse] {
        response.content.compactMap { block in
            if case let .toolUse(id, name, input) = block {
                return ExtractedToolUse(id: id, name: name, input: input)
            }
            return nil
        }
    }
}
