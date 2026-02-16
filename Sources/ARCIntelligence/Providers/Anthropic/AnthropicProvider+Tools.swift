//
//  AnthropicProvider+Tools.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import ARCLogger
import Foundation

// MARK: - ToolProvider Conformance

extension AnthropicProvider: ToolProvider {
    /// Generate a response using the provided tools.
    ///
    /// Implements the Anthropic tool calling loop:
    /// 1. Send request with tool definitions
    /// 2. If model returns `tool_use`, execute the tool locally
    /// 3. Send tool result back as a `tool_result` content block
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

        let context = ToolCallingContext(toolDefinitions: tools.map { mapToolToDefinition($0) },
                                         toolsByName: Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) }),
                                         systemPrompt: configuration.systemPrompt ?? self.configuration
                                             .defaultInstructions,
                                         maxTokens: configuration.maxTokens ?? self.configuration.defaultMaxTokens,
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

private struct ToolCallingContext {
    let toolDefinitions: [AnthropicToolDefinition]
    let toolsByName: [String: any IntelligenceTool]
    let systemPrompt: String?
    let maxTokens: Int
    let configuration: CompletionConfiguration
}

extension AnthropicProvider {
    private func executeToolLoop(context: ToolCallingContext,
                                 prompt: String) async throws -> (AnthropicMessageResponse, [ToolCallRecord]) {
        var messages: [AnthropicAPIMessage] = [AnthropicAPIMessage(role: "user", text: prompt)]
        var allToolCalls: [ToolCallRecord] = []

        for round in 0 ..< configuration.maxToolRounds {
            let request = buildToolRequest(context: context, messages: messages)
            let response = try await apiClient.sendMessage(request)
            let toolUseBlocks = extractToolUseBlocks(from: response)

            if toolUseBlocks.isEmpty || response.stopReason != "tool_use" {
                return (response, allToolCalls)
            }

            appendAssistantBlocks(from: response, to: &messages)
            let (resultBlocks, calls) = try await executePendingTools(toolUseBlocks,
                                                                      context: context)
            allToolCalls.append(contentsOf: calls)
            messages.append(AnthropicAPIMessage(role: "user", blocks: resultBlocks))

            logger.debug("Tool round completed", metadata: [
                "round": .public("\(round + 1)"),
                "toolCalls": .public("\(toolUseBlocks.count)")
            ])
        }

        logger.warning("Max tool rounds exceeded")
        throw IntelligenceError.requestFailed("Exceeded maximum tool calling rounds (\(configuration.maxToolRounds))")
    }

    private func buildToolRequest(context: ToolCallingContext,
                                  messages: [AnthropicAPIMessage]) -> AnthropicMessageRequest {
        AnthropicMessageRequest(model: configuration.model.modelId,
                                messages: messages,
                                maxTokens: context.maxTokens,
                                system: context.systemPrompt,
                                temperature: Double(context.configuration.temperature),
                                topP: context.configuration.topP.map { Double($0) },
                                stopSequences: context.configuration.stopSequences.isEmpty
                                    ? nil
                                    : context.configuration.stopSequences,
                                stream: false,
                                tools: context.toolDefinitions,
                                toolChoice: .auto)
    }

    private func appendAssistantBlocks(from response: AnthropicMessageResponse,
                                       to messages: inout [AnthropicAPIMessage]) {
        let blocks = response.content.map { block -> AnthropicContentBlock in
            switch block {
            case let .text(text):
                .text(text)
            case let .toolUse(id, name, input):
                .toolUse(id: id, name: name, input: input)
            }
        }
        messages.append(AnthropicAPIMessage(role: "assistant", blocks: blocks))
    }

    private func executePendingTools(_ toolUseBlocks: [ExtractedToolUse],
                                     context: ToolCallingContext) async throws -> ([AnthropicContentBlock],
                                                                                   [ToolCallRecord]) {
        var resultBlocks: [AnthropicContentBlock] = []
        var records: [ToolCallRecord] = []

        for toolUse in toolUseBlocks {
            let (block, record) = await executeSingleTool(toolUse, context: context)
            resultBlocks.append(block)
            records.append(record)
        }

        return (resultBlocks, records)
    }

    private func executeSingleTool(_ toolUse: ExtractedToolUse,
                                   context: ToolCallingContext) async -> (AnthropicContentBlock, ToolCallRecord) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let arguments = toolUse.input.mapValues(\.toAny)
        let stringArguments = toolUse.input.compactMapValues { value -> String? in
            if case let .string(str) = value { return str }
            return "\(value)"
        }

        var output: String
        var isError = false

        if let tool = context.toolsByName[toolUse.name] {
            do {
                output = try await tool.execute(arguments: arguments)
            } catch {
                output = "Error: \(error.localizedDescription)"
                isError = true
                logger.warning("Tool execution failed", metadata: [
                    "tool": .public(toolUse.name),
                    "error": .public(error.localizedDescription)
                ])
            }
        } else {
            output = "Error: Unknown tool '\(toolUse.name)'"
            isError = true
            logger.warning("Unknown tool requested", metadata: ["tool": .public(toolUse.name)])
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let record = ToolCallRecord(toolName: toolUse.name,
                                    arguments: stringArguments,
                                    output: output,
                                    duration: duration)
        let block = AnthropicContentBlock.toolResult(toolUseId: toolUse.id,
                                                     content: output,
                                                     isError: isError ? true : nil)

        return (block, record)
    }
}
