//
//  OpenAICompatibleAPIModels.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

// MARK: - Request Types

/// Request body for the OpenAI Chat Completions API.
struct OpenAIChatRequest: Codable, Sendable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Double?
    let topP: Double?
    let maxTokens: Int?
    let stop: [String]?
    let stream: Bool
    let tools: [OpenAIToolDefinition]?
    let toolChoice: OpenAIToolChoice?
    let responseFormat: OpenAIResponseFormat?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stop, stream, tools
        case topP = "top_p"
        case maxTokens = "max_tokens"
        case toolChoice = "tool_choice"
        case responseFormat = "response_format"
    }
}

/// A single message in the OpenAI Chat API format.
struct OpenAIChatMessage: Codable, Sendable {
    let role: String
    let content: String?
    let toolCalls: [OpenAIToolCall]?
    let toolCallId: String?

    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }

    init(role: String, content: String?, toolCalls: [OpenAIToolCall]? = nil, toolCallId: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }

    init(role: String, text: String) {
        self.role = role
        content = text
        toolCalls = nil
        toolCallId = nil
    }

    init(role: String, toolCallId: String, content: String) {
        self.role = role
        self.content = content
        self.toolCallId = toolCallId
        toolCalls = nil
    }
}

/// Optional response format specification.
struct OpenAIResponseFormat: Codable, Sendable {
    let type: String

    static let jsonObject = OpenAIResponseFormat(type: "json_object")
}

// MARK: - Response Types

/// Response from the OpenAI Chat Completions API.
struct OpenAIChatResponse: Codable, Sendable {
    let id: String
    let object: String
    let model: String
    let choices: [OpenAIChatChoice]
    let usage: OpenAIUsage?
}

/// A single choice in the response.
struct OpenAIChatChoice: Codable, Sendable {
    let index: Int
    let message: OpenAIChatChoiceMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

/// Message content within a response choice.
struct OpenAIChatChoiceMessage: Codable, Sendable {
    let role: String
    let content: String?
    let toolCalls: [OpenAIToolCall]?

    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
    }
}

/// Token usage information.
struct OpenAIUsage: Codable, Sendable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Tool Types

/// Tool definition for the OpenAI API.
struct OpenAIToolDefinition: Codable, Sendable {
    let type: String
    let function: OpenAIFunctionDefinition

    init(function: OpenAIFunctionDefinition) {
        type = "function"
        self.function = function
    }
}

/// Function definition within a tool.
struct OpenAIFunctionDefinition: Codable, Sendable {
    let name: String
    let description: String
    let parameters: OpenAIFunctionParameters
}

/// JSON Schema for function parameters.
struct OpenAIFunctionParameters: Codable, Sendable {
    let type: String
    let properties: [String: OpenAISchemaProperty]?
    let required: [String]?

    init(type: String = "object",
         properties: [String: OpenAISchemaProperty]? = nil,
         required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

/// A single property in a JSON Schema.
struct OpenAISchemaProperty: Codable, Sendable {
    let type: String
    let description: String?
    let enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}

/// A tool call made by the model.
struct OpenAIToolCall: Codable, Sendable {
    let id: String
    let type: String
    let function: OpenAIFunctionCall
}

/// Function call details within a tool call.
struct OpenAIFunctionCall: Codable, Sendable {
    let name: String
    let arguments: String
}

/// Tool choice specification.
enum OpenAIToolChoice: Sendable, Equatable {
    case auto
    case none
    case required
    case function(name: String)
}

extension OpenAIToolChoice: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            switch stringValue {
            case "auto":
                self = .auto
            case "none":
                self = .none
            case "required":
                self = .required
            default:
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Unknown tool choice: \(stringValue)")
            }
            return
        }

        let object = try container.decode(ToolChoiceObject.self)
        self = .function(name: object.function.name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .auto:
            try container.encode("auto")
        case .none:
            try container.encode("none")
        case .required:
            try container.encode("required")
        case let .function(name):
            try container.encode(ToolChoiceObject(type: "function",
                                                  function: ToolChoiceFunctionRef(name: name)))
        }
    }
}

/// Helper struct for encoding/decoding function tool choice.
private struct ToolChoiceObject: Codable {
    let type: String
    let function: ToolChoiceFunctionRef
}

/// Helper struct for encoding/decoding function name reference.
private struct ToolChoiceFunctionRef: Codable {
    let name: String
}

// MARK: - Streaming Types

/// A single chunk in a streaming response.
struct OpenAIStreamChunk: Codable, Sendable {
    let id: String?
    let choices: [OpenAIStreamChoice]?
    let usage: OpenAIUsage?
}

/// A single choice in a streaming chunk.
struct OpenAIStreamChoice: Codable, Sendable {
    let index: Int
    let delta: OpenAIStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
}

/// Delta content in a streaming chunk.
struct OpenAIStreamDelta: Codable, Sendable {
    let role: String?
    let content: String?
    let toolCalls: [OpenAIToolCall]?

    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
    }
}

// MARK: - Error Types

/// Error response from the OpenAI API.
struct OpenAIErrorResponse: Codable, Sendable {
    let error: OpenAIErrorDetail
}

/// Error detail from the API.
struct OpenAIErrorDetail: Codable, Sendable {
    let message: String
    let type: String?
    let code: String?
}
