//
//  OpenAICompatibleMapping.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

/// Shared mapping helpers for OpenAI-compatible providers (OpenAI and Grok).
///
/// Contains static methods to reduce duplication between providers that share
/// the same Chat Completions API format.
enum OpenAICompatibleMapping {
    // MARK: - Provider Defaults

    /// Groups provider-specific defaults to reduce parameter counts.
    struct ProviderDefaults {
        let modelId: String
        let defaultInstructions: String?
        let defaultMaxTokens: Int
    }

    // MARK: - Request Building

    /// Build a chat completion request from a prompt and configuration.
    static func buildRequest(prompt: String,
                             defaults: ProviderDefaults,
                             configuration: CompletionConfiguration,
                             stream: Bool = false,
                             tools: [OpenAIToolDefinition]? = nil,
                             toolChoice: OpenAIToolChoice? = nil) -> OpenAIChatRequest {
        let systemPrompt = configuration.systemPrompt ?? defaults.defaultInstructions

        var messages: [OpenAIChatMessage] = []
        if let systemPrompt {
            messages.append(OpenAIChatMessage(role: "system", text: systemPrompt))
        }
        messages.append(OpenAIChatMessage(role: "user", text: prompt))

        let maxTokens = configuration.maxTokens ?? defaults.defaultMaxTokens

        return OpenAIChatRequest(model: defaults.modelId,
                                 messages: messages,
                                 temperature: Double(configuration.temperature),
                                 topP: configuration.topP.map { Double($0) },
                                 maxTokens: maxTokens,
                                 stop: configuration.stopSequences.isEmpty
                                     ? nil
                                     : configuration.stopSequences,
                                 stream: stream,
                                 tools: tools,
                                 toolChoice: toolChoice,
                                 responseFormat: nil)
    }

    /// Build a chat completion request from a conversation.
    static func buildConversationRequest(conversation: Conversation,
                                         newMessage: Message,
                                         defaults: ProviderDefaults,
                                         configuration: CompletionConfiguration,
                                         stream: Bool = false) -> OpenAIChatRequest {
        var apiMessages: [OpenAIChatMessage] = []

        let systemPrompt = conversation.systemPrompt
            ?? configuration.systemPrompt
            ?? defaults.defaultInstructions

        if let systemPrompt {
            apiMessages.append(OpenAIChatMessage(role: "system", text: systemPrompt))
        }

        for message in conversation.messages {
            switch message.role {
            case .user:
                apiMessages.append(OpenAIChatMessage(role: "user", text: message.content))
            case .assistant:
                apiMessages.append(OpenAIChatMessage(role: "assistant", text: message.content))
            case .system:
                // System messages are already added above
                break
            }
        }

        if newMessage.role == .user {
            apiMessages.append(OpenAIChatMessage(role: "user", text: newMessage.content))
        }

        let maxTokens = configuration.maxTokens ?? defaults.defaultMaxTokens

        return OpenAIChatRequest(model: defaults.modelId,
                                 messages: apiMessages,
                                 temperature: Double(configuration.temperature),
                                 topP: configuration.topP.map { Double($0) },
                                 maxTokens: maxTokens,
                                 stop: configuration.stopSequences.isEmpty
                                     ? nil
                                     : configuration.stopSequences,
                                 stream: stream,
                                 tools: nil,
                                 toolChoice: nil,
                                 responseFormat: nil)
    }

    // MARK: - Response Mapping

    /// Map a chat completion response to an `IntelligenceResponse`.
    static func mapResponse(_ response: OpenAIChatResponse) -> IntelligenceResponse {
        let textContent = response.choices.first?.message.content ?? ""
        let tokensUsed = response.usage?.totalTokens ?? 0
        let finishReason = mapStopReason(response.choices.first?.finishReason)

        return IntelligenceResponse(content: textContent,
                                    tokensUsed: tokensUsed,
                                    finishReason: finishReason,
                                    metadata: [
                                        "model": response.model,
                                        "promptTokens": "\(response.usage?.promptTokens ?? 0)",
                                        "completionTokens": "\(response.usage?.completionTokens ?? 0)"
                                    ])
    }

    /// Map a finish reason string to `FinishReason`.
    static func mapStopReason(_ finishReason: String?) -> IntelligenceResponse.FinishReason {
        switch finishReason {
        case "stop":
            .completed
        case "length":
            .maxTokens
        case "content_filter":
            .contentFilter
        case "tool_calls":
            .completed
        default:
            .unknown
        }
    }

    // MARK: - Tool Schema Mapping

    /// Convert an `IntelligenceTool` to an `OpenAIToolDefinition`.
    static func mapToolToDefinition(_ tool: any IntelligenceTool) -> OpenAIToolDefinition {
        let parameters: OpenAIFunctionParameters

        if let schema = tool.parametersSchema {
            var properties: [String: OpenAISchemaProperty] = [:]
            for param in schema.parameters {
                properties[param.name] = OpenAISchemaProperty(type: param.type.rawValue,
                                                              description: param.description,
                                                              enumValues: param.enumValues)
            }

            parameters = OpenAIFunctionParameters(type: "object",
                                                  properties: properties,
                                                  required: schema.required.isEmpty ? nil : schema.required)
        } else {
            parameters = OpenAIFunctionParameters(type: "object")
        }

        let function = OpenAIFunctionDefinition(name: tool.name,
                                                description: tool.description,
                                                parameters: parameters)

        return OpenAIToolDefinition(function: function)
    }

    // MARK: - Tool Call Extraction

    /// Represents a tool call extracted from an API response.
    struct ExtractedToolCall {
        let id: String
        let name: String
        let arguments: String
    }

    /// Extract tool calls from a response.
    static func extractToolCalls(from response: OpenAIChatResponse) -> [ExtractedToolCall] {
        guard let toolCalls = response.choices.first?.message.toolCalls else {
            return []
        }

        return toolCalls.map { call in
            ExtractedToolCall(id: call.id,
                              name: call.function.name,
                              arguments: call.function.arguments)
        }
    }

    // MARK: - Generable Helpers

    /// Build a generation request using forced function calling.
    static func buildGenerationRequest(_ type: (some Any).Type,
                                       prompt: String,
                                       schemaDescription: String?,
                                       defaults: ProviderDefaults,
                                       configuration: CompletionConfiguration) -> OpenAIChatRequest {
        let toolName = "generate_\(String(describing: type).lowercased())"
        let description = schemaDescription
            ?? "Generate a structured \(String(describing: type)) response."

        let jsonOutputDescription = "The complete JSON object as a string conforming to the requested type."
        let jsonOutputProperty = OpenAISchemaProperty(type: "string",
                                                      description: jsonOutputDescription,
                                                      enumValues: nil)

        let parameters = OpenAIFunctionParameters(type: "object",
                                                  properties: ["json_output": jsonOutputProperty],
                                                  required: ["json_output"])
        let function = OpenAIFunctionDefinition(name: toolName,
                                                description: description,
                                                parameters: parameters)
        let toolDefinition = OpenAIToolDefinition(function: function)

        let systemPrompt = configuration.systemPrompt ?? defaults.defaultInstructions
        let maxTokens = configuration.maxTokens ?? defaults.defaultMaxTokens
        let enhancedPrompt = """
        \(prompt)

        You MUST call the \(toolName) tool with the result as valid JSON in the json_output field.
        """

        var messages: [OpenAIChatMessage] = []
        if let systemPrompt {
            messages.append(OpenAIChatMessage(role: "system", text: systemPrompt))
        }
        messages.append(OpenAIChatMessage(role: "user", text: enhancedPrompt))

        return OpenAIChatRequest(model: defaults.modelId,
                                 messages: messages,
                                 temperature: Double(configuration.temperature),
                                 topP: configuration.topP.map { Double($0) },
                                 maxTokens: maxTokens,
                                 stop: nil,
                                 stream: false,
                                 tools: [toolDefinition],
                                 toolChoice: .function(name: toolName),
                                 responseFormat: nil)
    }

    /// Decode a JSON string into a Codable type.
    static func decodeJSON<T: Codable>(_ jsonString: String, type: T.Type) throws -> T {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw IntelligenceError.responseParseFailed("Unable to convert tool output to data")
        }

        do {
            return try JSONDecoder().decode(type, from: jsonData)
        } catch {
            throw IntelligenceError
                .responseParseFailed("Failed to decode response as \(type): \(error.localizedDescription)")
        }
    }

    /// Parse tool call arguments and extract `json_output` value.
    static func extractJsonOutput(from arguments: String) throws -> String? {
        guard let data = arguments.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jsonOutput = dict["json_output"] as? String
        else {
            return nil
        }
        return jsonOutput
    }
}
