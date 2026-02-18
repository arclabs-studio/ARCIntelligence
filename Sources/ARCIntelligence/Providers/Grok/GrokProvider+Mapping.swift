//
//  GrokProvider+Mapping.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

// MARK: - Mapping Helpers

extension GrokProvider {
    // MARK: - Request Building

    /// Build an API request from a prompt and configuration.
    func buildRequest(prompt: String,
                      configuration: CompletionConfiguration,
                      stream: Bool = false,
                      tools: [OpenAIToolDefinition]? = nil,
                      toolChoice: OpenAIToolChoice? = nil) -> OpenAIChatRequest {
        OpenAICompatibleMapping.buildRequest(prompt: prompt,
                                             modelId: self.configuration.model.modelId,
                                             defaultInstructions: self.configuration.defaultInstructions,
                                             defaultMaxTokens: self.configuration.defaultMaxTokens,
                                             configuration: configuration,
                                             stream: stream,
                                             tools: tools,
                                             toolChoice: toolChoice)
    }

    /// Build an API request from a conversation.
    func buildConversationRequest(conversation: Conversation,
                                  newMessage: Message,
                                  configuration: CompletionConfiguration,
                                  stream: Bool = false) -> OpenAIChatRequest {
        OpenAICompatibleMapping.buildConversationRequest(conversation: conversation,
                                                         newMessage: newMessage,
                                                         modelId: self.configuration.model.modelId,
                                                         defaultInstructions: self.configuration.defaultInstructions,
                                                         defaultMaxTokens: self.configuration.defaultMaxTokens,
                                                         configuration: configuration,
                                                         stream: stream)
    }

    // MARK: - Response Mapping

    /// Map an API response to an `IntelligenceResponse`.
    func mapResponse(_ response: OpenAIChatResponse) -> IntelligenceResponse {
        OpenAICompatibleMapping.mapResponse(response)
    }

    /// Map a finish reason string to `FinishReason`.
    func mapStopReason(_ finishReason: String?) -> IntelligenceResponse.FinishReason {
        OpenAICompatibleMapping.mapStopReason(finishReason)
    }

    // MARK: - Tool Schema Mapping

    /// Convert an `IntelligenceTool` to an `OpenAIToolDefinition`.
    func mapToolToDefinition(_ tool: any IntelligenceTool) -> OpenAIToolDefinition {
        OpenAICompatibleMapping.mapToolToDefinition(tool)
    }

    /// Extract tool calls from a response.
    func extractToolCalls(from response: OpenAIChatResponse) -> [OpenAICompatibleMapping.ExtractedToolCall] {
        OpenAICompatibleMapping.extractToolCalls(from: response)
    }
}
