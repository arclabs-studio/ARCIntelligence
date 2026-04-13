//
//  GeminiAPIModels.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

// MARK: - Request Types

/// Request body for the Gemini generateContent API.
///
/// The model name is carried here for URL construction and is excluded from
/// the JSON body via custom `CodingKeys`.
struct GeminiGenerateContentRequest {
    /// The model identifier used to construct the endpoint URL.
    let model: String
    let contents: [GeminiContent]
    let systemInstruction: GeminiContent?
    let generationConfig: GeminiGenerationConfig?
    let tools: [GeminiTool]?
    let toolConfig: GeminiToolConfig?
}

extension GeminiGenerateContentRequest: Encodable {
    /// Encodes only the body fields. `model` is part of the URL, not the request body.
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction
        case generationConfig
        case tools
        case toolConfig
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contents, forKey: .contents)
        try container.encodeIfPresent(systemInstruction, forKey: .systemInstruction)
        try container.encodeIfPresent(generationConfig, forKey: .generationConfig)
        try container.encodeIfPresent(tools, forKey: .tools)
        try container.encodeIfPresent(toolConfig, forKey: .toolConfig)
    }
}

/// A single turn of content in the conversation.
struct GeminiContent: Codable {
    /// The role of the author: "user" or "model".
    let role: String?
    let parts: [GeminiPart]

    init(role: String? = nil, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

/// A single part of a content block.
///
/// The Gemini API uses a tagged-union approach where each part
/// carries only one of several possible keys.
enum GeminiPart {
    case text(String)
    case functionCall(GeminiFunctionCall)
    case functionResponse(GeminiFunctionResponse)
}

extension GeminiPart: Codable {
    enum CodingKeys: String, CodingKey {
        case text
        case functionCall
        case functionResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self = .text(text)
        } else if let call = try container.decodeIfPresent(GeminiFunctionCall.self, forKey: .functionCall) {
            self = .functionCall(call)
        } else if let response = try container.decodeIfPresent(GeminiFunctionResponse.self,
                                                               forKey: .functionResponse) {
            self = .functionResponse(response)
        } else {
            // Unknown or unsupported part type (e.g. inlineData, executableCode).
            // Decode as empty text to avoid parse failures on mixed-content responses.
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(text):
            try container.encode(text, forKey: .text)
        case let .functionCall(call):
            try container.encode(call, forKey: .functionCall)
        case let .functionResponse(response):
            try container.encode(response, forKey: .functionResponse)
        }
    }
}

/// A function call returned by the model.
struct GeminiFunctionCall: Codable {
    let name: String
    /// Optional call ID used to correlate with the function response.
    let id: String?
    /// The arguments the model wants to pass to the function.
    let args: [String: AnyCodableValue]?
}

/// A function result sent back to the model.
struct GeminiFunctionResponse: Codable {
    let name: String
    /// The call ID from the corresponding `GeminiFunctionCall`.
    let id: String?
    /// The function output, keyed arbitrarily.
    let response: [String: AnyCodableValue]
}

/// Generation parameters.
struct GeminiGenerationConfig: Codable {
    let temperature: Float?
    let maxOutputTokens: Int?
    let topP: Float?
    let topK: Int?
    let stopSequences: [String]?
    let candidateCount: Int?
}

/// Container for function declarations passed to the model.
struct GeminiTool: Codable {
    let functionDeclarations: [GeminiFunctionDeclaration]?
}

/// A single function the model may call.
struct GeminiFunctionDeclaration: Codable {
    let name: String
    let description: String
    let parameters: GeminiSchema?
}

/// JSON Schema for function parameters.
struct GeminiSchema: Codable {
    let type: String
    let properties: [String: GeminiSchemaProperty]?
    let required: [String]?

    init(type: String = "object",
         properties: [String: GeminiSchemaProperty]? = nil,
         required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

/// A single property in a function schema.
struct GeminiSchemaProperty: Codable {
    let type: String
    let description: String?
    let enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}

/// Controls how the model selects functions to call.
struct GeminiToolConfig: Codable {
    let functionCallingConfig: GeminiFunctionCallingConfig

    enum CodingKeys: String, CodingKey {
        case functionCallingConfig
    }
}

/// Fine-grained control over function calling behaviour.
struct GeminiFunctionCallingConfig: Codable {
    /// "AUTO" lets the model decide, "ANY" forces a function call, "NONE" disables it.
    let mode: String
    /// When `mode` is "ANY", restrict to these function names.
    let allowedFunctionNames: [String]?

    enum CodingKeys: String, CodingKey {
        case mode
        case allowedFunctionNames
    }
}

// MARK: - Response Types

/// The full response from `generateContent` (streaming or non-streaming).
struct GeminiGenerateContentResponse: Codable {
    let candidates: [GeminiCandidate]?
    let usageMetadata: GeminiUsageMetadata?
    let modelVersion: String?
}

/// A single response candidate.
struct GeminiCandidate: Codable {
    let content: GeminiContent?
    /// "STOP", "MAX_TOKENS", "SAFETY", "RECITATION", "OTHER".
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case content, finishReason
    }
}

/// Token usage information.
struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

// MARK: - Error Response

/// Error response body from the Gemini API.
struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail
}

/// Detail inside an error response.
struct GeminiErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}
