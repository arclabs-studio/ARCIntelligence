//
//  OpenAICompatibleProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import ARCLogger
import Foundation

// MARK: - Protocol

/// Internal protocol adopted by all OpenAI-compatible providers (OpenAI, Grok).
///
/// Inherits `GenerableProvider` and `ToolProvider` and provides default
/// implementations for both, so concrete providers only need to supply their
/// API client, logger, and provider-specific defaults.  Adding a new
/// OpenAI-compatible provider requires conforming to this protocol and
/// implementing four requirements.
protocol OpenAICompatibleProvider: AnyObject, GenerableProvider, ToolProvider {
    /// The API client used to send requests.
    var apiClient: OpenAICompatibleAPIClient { get }

    /// Logger for this provider.
    var logger: ARCLogger { get }

    /// Provider-specific defaults passed to mapping helpers.
    var providerDefaults: OpenAICompatibleMapping.ProviderDefaults { get }

    /// Maximum number of tool-calling rounds per request.
    var maxToolRounds: Int { get }
}

// MARK: - Mapping Helpers

extension OpenAICompatibleProvider {
    func buildRequest(prompt: String,
                      configuration: CompletionConfiguration,
                      stream: Bool = false,
                      tools: [OpenAIToolDefinition]? = nil,
                      toolChoice: OpenAIToolChoice? = nil) -> OpenAIChatRequest {
        OpenAICompatibleMapping.buildRequest(prompt: prompt,
                                             defaults: providerDefaults,
                                             configuration: configuration,
                                             stream: stream,
                                             tools: tools,
                                             toolChoice: toolChoice)
    }

    func buildConversationRequest(conversation: Conversation,
                                  newMessage: Message,
                                  configuration: CompletionConfiguration,
                                  stream: Bool = false) -> OpenAIChatRequest {
        OpenAICompatibleMapping.buildConversationRequest(conversation: conversation,
                                                         newMessage: newMessage,
                                                         defaults: providerDefaults,
                                                         configuration: configuration,
                                                         stream: stream)
    }

    func mapResponse(_ response: OpenAIChatResponse) -> IntelligenceResponse {
        OpenAICompatibleMapping.mapResponse(response)
    }

    func mapStopReason(_ finishReason: String?) -> IntelligenceResponse.FinishReason {
        OpenAICompatibleMapping.mapStopReason(finishReason)
    }

    func mapToolToDefinition(_ tool: any IntelligenceTool) -> OpenAIToolDefinition {
        OpenAICompatibleMapping.mapToolToDefinition(tool)
    }

    func extractToolCalls(from response: OpenAIChatResponse) -> [OpenAICompatibleMapping.ExtractedToolCall] {
        OpenAICompatibleMapping.extractToolCalls(from: response)
    }
}

// MARK: - GenerableProvider Default Implementations

extension OpenAICompatibleProvider {
    /// Generate a structured response using forced function calling.
    ///
    /// Internally creates a tool whose input schema matches the JSON structure
    /// of `T`, forces the model to call it via `tool_choice`, and decodes the
    /// tool call arguments as `T`.
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

    private func performGeneration<T: Codable & Sendable>(_ type: T.Type,
                                                          prompt: String,
                                                          schemaDescription: String?,
                                                          configuration: CompletionConfiguration) async throws -> T {
        logger.debug("Starting structured generation", metadata: [
            "type": .public(String(describing: type)),
            "promptLength": .public("\(prompt.count)")
        ])

        let request = OpenAICompatibleMapping.buildGenerationRequest(type,
                                                                     prompt: prompt,
                                                                     schemaDescription: schemaDescription,
                                                                     defaults: providerDefaults,
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

        // Fallback: try decoding the arguments string directly
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

// MARK: - ToolProvider Default Implementations

private struct OpenAICompatibleToolCallingContext {
    let toolDefinitions: [OpenAIToolDefinition]
    let toolsByName: [String: any IntelligenceTool]
    let systemPrompt: String?
    let maxTokens: Int
    let configuration: CompletionConfiguration
}

extension OpenAICompatibleProvider {
    /// Generate a response using the provided tools.
    ///
    /// Implements the OpenAI-compatible tool calling loop:
    /// 1. Send request with tool definitions
    /// 2. If model returns `tool_calls`, execute each tool locally
    /// 3. Send tool results back as individual `role: "tool"` messages
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
    -> (response: IntelligenceResponse, toolCalls: [ToolCallRecord]) {
        logger.debug("Starting tool-assisted generation", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "toolCount": .public("\(tools.count)")
        ])

        let context = OpenAICompatibleToolCallingContext(toolDefinitions: tools.map { mapToolToDefinition($0) },
                                                         toolsByName: Dictionary(uniqueKeysWithValues: tools
                                                             .map { ($0.name,
                                                                     $0)
                                                             }),
                                                         systemPrompt: configuration.systemPrompt ?? providerDefaults
                                                             .defaultInstructions,
                                                         maxTokens: configuration.maxTokens ?? providerDefaults
                                                             .defaultMaxTokens,
                                                         configuration: configuration)

        let (response, allToolCalls) = try await executeToolLoop(context: context, prompt: prompt)
        let intelligenceResponse = mapResponse(response)

        logger.info("Tool-assisted generation successful",
                    metadata: [
                        "totalToolCalls": .public("\(allToolCalls.count)"),
                        "tokensUsed": .public("\(intelligenceResponse.tokensUsed)")
                    ])

        return (intelligenceResponse, allToolCalls)
    }

    private func executeToolLoop(context: OpenAICompatibleToolCallingContext,
                                 prompt: String) async throws -> (OpenAIChatResponse, [ToolCallRecord]) {
        var messages: [OpenAIChatMessage] = []

        if let systemPrompt = context.systemPrompt {
            messages.append(OpenAIChatMessage(role: "system", text: systemPrompt))
        }
        messages.append(OpenAIChatMessage(role: "user", text: prompt))

        var allToolCalls: [ToolCallRecord] = []

        for round in 0 ..< maxToolRounds {
            let request = buildToolRequest(context: context, messages: messages)
            let response = try await apiClient.sendChatCompletion(request)
            let toolCalls = extractToolCalls(from: response)

            if toolCalls.isEmpty || response.choices.first?.finishReason != "tool_calls" {
                return (response, allToolCalls)
            }

            // Append the assistant message with tool calls
            appendAssistantMessage(from: response, to: &messages)

            let (toolMessages, records) = await executePendingTools(toolCalls, context: context)
            allToolCalls.append(contentsOf: records)
            messages.append(contentsOf: toolMessages)

            logger.debug("Tool round completed", metadata: [
                "round": .public("\(round + 1)"),
                "toolCalls": .public("\(toolCalls.count)")
            ])
        }

        logger.warning("Max tool rounds exceeded")
        throw IntelligenceError.requestFailed("Exceeded maximum tool calling rounds (\(maxToolRounds))")
    }

    private func buildToolRequest(context: OpenAICompatibleToolCallingContext,
                                  messages: [OpenAIChatMessage]) -> OpenAIChatRequest {
        OpenAIChatRequest(model: providerDefaults.modelId,
                          messages: messages,
                          temperature: Double(context.configuration.temperature),
                          topP: context.configuration.topP.map { Double($0) },
                          maxTokens: context.maxTokens,
                          stop: context.configuration.stopSequences.isEmpty ? nil : context.configuration.stopSequences,
                          stream: false,
                          tools: context.toolDefinitions,
                          toolChoice: .auto,
                          responseFormat: nil)
    }

    private func appendAssistantMessage(from response: OpenAIChatResponse,
                                        to messages: inout [OpenAIChatMessage]) {
        guard let choice = response.choices.first else { return }
        let assistantMessage = OpenAIChatMessage(role: "assistant",
                                                 content: choice.message.content,
                                                 toolCalls: choice.message.toolCalls,
                                                 toolCallId: nil)
        messages.append(assistantMessage)
    }

    private func executePendingTools(_ toolCalls: [OpenAICompatibleMapping.ExtractedToolCall],
                                     context: OpenAICompatibleToolCallingContext) async
    -> ([OpenAIChatMessage], [ToolCallRecord]) {
        var toolMessages: [OpenAIChatMessage] = []
        toolMessages.reserveCapacity(toolCalls.count)
        var records: [ToolCallRecord] = []
        records.reserveCapacity(toolCalls.count)

        for toolCall in toolCalls {
            let (message, record) = await executeSingleTool(toolCall, context: context)
            toolMessages.append(message)
            records.append(record)
        }

        return (toolMessages, records)
    }

    private func executeSingleTool(_ toolCall: OpenAICompatibleMapping.ExtractedToolCall,
                                   context: OpenAICompatibleToolCallingContext) async
    -> (OpenAIChatMessage, ToolCallRecord) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let arguments: [String: ToolArgumentValue]
        let stringArguments: [String: String]

        if let data = toolCall.arguments.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: ToolArgumentValue].self, from: data) {
            arguments = dict
            stringArguments = ToolArgumentValue.toStringDictionary(dict)
        } else {
            arguments = [:]
            stringArguments = [:]
        }

        var output: String

        if let tool = context.toolsByName[toolCall.name] {
            do {
                output = try await tool.execute(arguments: arguments)
            } catch {
                output = "Error: \(error.localizedDescription)"
                logger.warning("Tool execution failed", metadata: [
                    "tool": .public(toolCall.name),
                    "error": .public(error.localizedDescription)
                ])
            }
        } else {
            output = "Error: Unknown tool '\(toolCall.name)'"
            logger.warning("Unknown tool requested", metadata: ["tool": .public(toolCall.name)])
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let record = ToolCallRecord(toolName: toolCall.name,
                                    arguments: stringArguments,
                                    output: output,
                                    duration: duration)

        let message = OpenAIChatMessage(role: "tool",
                                        toolCallId: toolCall.id,
                                        content: output)

        return (message, record)
    }
}
