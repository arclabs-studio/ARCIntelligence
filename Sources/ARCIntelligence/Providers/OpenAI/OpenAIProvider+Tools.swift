//
//  OpenAIProvider+Tools.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import ARCLogger
import Foundation

// MARK: - ToolProvider Conformance

extension OpenAIProvider: ToolProvider {
    /// Generate a response using the provided tools.
    ///
    /// Implements the OpenAI tool calling loop:
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
        -> (response: IntelligenceResponse,
            toolCalls: [ToolCallRecord]) {
        logger.debug("Starting tool-assisted generation", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "toolCount": .public("\(tools.count)")
        ])

        let context = OpenAIToolCallingContext(toolDefinitions: tools.map { mapToolToDefinition($0) },
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
                    metadata: [
                        "totalToolCalls": .public("\(allToolCalls.count)"),
                        "tokensUsed": .public("\(intelligenceResponse.tokensUsed)")
                    ])

        return (intelligenceResponse, allToolCalls)
    }
}

// MARK: - Private Tool Calling Helpers

private struct OpenAIToolCallingContext {
    let toolDefinitions: [OpenAIToolDefinition]
    let toolsByName: [String: any IntelligenceTool]
    let systemPrompt: String?
    let maxTokens: Int
    let configuration: CompletionConfiguration
}

extension OpenAIProvider {
    private func executeToolLoop(context: OpenAIToolCallingContext,
                                 prompt: String) async throws -> (OpenAIChatResponse, [ToolCallRecord]) {
        var messages: [OpenAIChatMessage] = []

        if let systemPrompt = context.systemPrompt {
            messages.append(OpenAIChatMessage(role: "system", text: systemPrompt))
        }
        messages.append(OpenAIChatMessage(role: "user", text: prompt))

        var allToolCalls: [ToolCallRecord] = []

        for round in 0 ..< configuration.maxToolRounds {
            let request = buildToolRequest(context: context, messages: messages)
            let response = try await apiClient.sendChatCompletion(request)
            let toolCalls = extractToolCalls(from: response)

            if toolCalls.isEmpty || response.choices.first?.finishReason != "tool_calls" {
                return (response, allToolCalls)
            }

            // Append the assistant message with tool calls
            appendAssistantMessage(from: response, to: &messages)

            // Execute each tool and add result messages
            let (toolMessages, records) = await executePendingTools(toolCalls, context: context)
            allToolCalls.append(contentsOf: records)
            messages.append(contentsOf: toolMessages)

            logger.debug("Tool round completed", metadata: [
                "round": .public("\(round + 1)"),
                "toolCalls": .public("\(toolCalls.count)")
            ])
        }

        logger.warning("Max tool rounds exceeded")
        throw IntelligenceError.requestFailed("Exceeded maximum tool calling rounds (\(configuration.maxToolRounds))")
    }

    private func buildToolRequest(context: OpenAIToolCallingContext,
                                  messages: [OpenAIChatMessage]) -> OpenAIChatRequest {
        OpenAIChatRequest(model: configuration.model.modelId,
                          messages: messages,
                          temperature: Double(context.configuration.temperature),
                          topP: context.configuration.topP.map { Double($0) },
                          maxTokens: context.maxTokens,
                          stop: context.configuration.stopSequences.isEmpty
                              ? nil
                              : context.configuration.stopSequences,
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
                                     context: OpenAIToolCallingContext) async -> ([OpenAIChatMessage], [
        ToolCallRecord
    ]) {
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
                                   context: OpenAIToolCallingContext) async -> (OpenAIChatMessage, ToolCallRecord) {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Parse arguments JSON to [String: ToolArgumentValue]
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
