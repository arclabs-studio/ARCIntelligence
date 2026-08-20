//
//  AnthropicAPIModels.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation

// MARK: - Request Types

/// Request body for the Anthropic Messages API.
struct AnthropicMessageRequest: Codable, Sendable {
    let model: String
    let messages: [AnthropicAPIMessage]
    let maxTokens: Int
    let system: String?
    let temperature: Double?
    let topP: Double?
    let stopSequences: [String]?
    let stream: Bool
    let tools: [AnthropicToolDefinition]?
    let toolChoice: AnthropicToolChoice?

    enum CodingKeys: String, CodingKey {
        case model, messages, system, temperature, stream, tools
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case stopSequences = "stop_sequences"
        case toolChoice = "tool_choice"
    }
}

/// A single message in the API format.
struct AnthropicAPIMessage: Codable, Sendable {
    let role: String
    let content: AnthropicAPIContent

    init(role: String, text: String) {
        self.role = role
        content = .text(text)
    }

    init(role: String, blocks: [AnthropicContentBlock]) {
        self.role = role
        content = .blocks(blocks)
    }
}

/// Content can be a simple string or an array of content blocks.
enum AnthropicAPIContent: Codable, Sendable {
    case text(String)
    case blocks([AnthropicContentBlock])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            let blocks = try container.decode([AnthropicContentBlock].self)
            self = .blocks(blocks)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .text(string):
            try container.encode(string)
        case let .blocks(blocks):
            try container.encode(blocks)
        }
    }
}

/// A content block in a message.
enum AnthropicContentBlock: Codable, Sendable {
    case text(String)
    case toolUse(id: String, name: String, input: [String: AnyCodableValue])
    case toolResult(toolUseId: String, content: String, isError: Bool?)

    enum CodingKeys: String, CodingKey {
        case type, text, id, name, input, content
        case toolUseId = "tool_use_id"
        case isError = "is_error"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode([String: AnyCodableValue].self, forKey: .input)
            self = .toolUse(id: id, name: name, input: input)
        case "tool_result":
            let toolUseId = try container.decode(String.self, forKey: .toolUseId)
            let content = try container.decode(String.self, forKey: .content)
            let isError = try container.decodeIfPresent(Bool.self, forKey: .isError)
            self = .toolResult(toolUseId: toolUseId, content: content, isError: isError)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown content block type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .text(text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case let .toolUse(id, name, input):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        case let .toolResult(toolUseId, content, isError):
            try container.encode("tool_result", forKey: .type)
            try container.encode(toolUseId, forKey: .toolUseId)
            try container.encode(content, forKey: .content)
            if let isError {
                try container.encode(isError, forKey: .isError)
            }
        }
    }
}

// MARK: - Response Types

/// Response from the Anthropic Messages API.
struct AnthropicMessageResponse: Codable, Sendable {
    let id: String
    let type: String
    let model: String
    let content: [AnthropicResponseContentBlock]
    let stopReason: String?
    let usage: AnthropicUsage

    enum CodingKeys: String, CodingKey {
        case id, type, model, content, usage
        case stopReason = "stop_reason"
    }
}

/// A content block in the response.
enum AnthropicResponseContentBlock: Codable, Sendable {
    case text(String)
    case toolUse(id: String, name: String, input: [String: AnyCodableValue])

    enum CodingKeys: String, CodingKey {
        case type, text, id, name, input
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode([String: AnyCodableValue].self, forKey: .input)
            self = .toolUse(id: id, name: name, input: input)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown response block type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .text(text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case let .toolUse(id, name, input):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        }
    }
}

/// Token usage information.
struct AnthropicUsage: Codable, Sendable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Tool Types

/// Tool definition for the Anthropic API.
struct AnthropicToolDefinition: Codable, Sendable {
    let name: String
    let description: String
    let inputSchema: AnthropicInputSchema

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

/// JSON Schema for tool input.
struct AnthropicInputSchema: Codable, Sendable {
    let type: String
    let properties: [String: AnthropicSchemaProperty]?
    let required: [String]?

    init(type: String = "object",
         properties: [String: AnthropicSchemaProperty]? = nil,
         required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

/// A single property in a JSON Schema.
struct AnthropicSchemaProperty: Codable, Sendable {
    let type: String
    let description: String?
    let enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}

/// Tool choice specification.
enum AnthropicToolChoice: Codable, Sendable, Equatable {
    case auto
    case any
    case tool(name: String)

    enum CodingKeys: String, CodingKey {
        case type, name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "auto":
            self = .auto
        case "any":
            self = .any
        case "tool":
            let name = try container.decode(String.self, forKey: .name)
            self = .tool(name: name)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown tool choice type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .auto:
            try container.encode("auto", forKey: .type)
        case .any:
            try container.encode("any", forKey: .type)
        case let .tool(name):
            try container.encode("tool", forKey: .type)
            try container.encode(name, forKey: .name)
        }
    }
}

// MARK: - Streaming Types

/// Events emitted during streaming.
enum AnthropicStreamEvent: Sendable {
    case messageStart(AnthropicMessageResponse)
    case contentBlockDelta(index: Int, text: String)
    case toolUseDelta(index: Int, partialJson: String)
    case contentBlockStart(index: Int, AnthropicResponseContentBlock)
    case contentBlockStop(index: Int)
    case messageDelta(stopReason: String?, usage: AnthropicUsage?)
    case messageStop
    case ping
}

// MARK: - Error Response

/// Error response from the Anthropic API.
struct AnthropicErrorResponse: Codable, Sendable {
    let type: String
    let error: AnthropicErrorDetail
}

/// Error detail from the API.
struct AnthropicErrorDetail: Codable, Sendable {
    let type: String
    let message: String
}

// MARK: - AnyCodableValue

/// Type-erased Codable value for dynamic JSON structures.
enum AnyCodableValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([AnyCodableValue])
    case object([String: AnyCodableValue])
}

extension AnyCodableValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodableValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode AnyCodableValue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

extension AnyCodableValue {
    /// Convert to `ToolArgumentValue` for tool execution arguments.
    var toToolArgumentValue: ToolArgumentValue {
        switch self {
        case let .string(value): .string(value)
        case let .int(value): .int(value)
        case let .double(value): .double(value)
        case let .bool(value): .bool(value)
        case .null: .null
        case let .array(value): .array(value.map(\.toToolArgumentValue))
        case let .object(value): .object(value.mapValues(\.toToolArgumentValue))
        }
    }
}
