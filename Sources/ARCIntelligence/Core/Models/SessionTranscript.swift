//
//  SessionTranscript.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Foundation

/// A linear history of entries that reflect interactions with an AI session.
///
/// `SessionTranscript` provides a cross-platform abstraction over session history,
/// allowing you to:
/// - Track all prompts and responses in a conversation
/// - Observe changes to the transcript (on iOS 26+)
/// - Persist and restore session state
/// - Build UI components showing conversation history
///
/// On iOS 26+, this wraps Apple's `Transcript` type from FoundationModels.
///
/// ## Example
/// ```swift
/// // Access transcript from a session
/// let transcript = session.transcript
///
/// // Iterate over entries
/// for entry in transcript.entries {
///     switch entry {
///     case .prompt(let prompt):
///         print("User: \(prompt.content)")
///     case .response(let response):
///         print("Assistant: \(response.content)")
///     case .instructions(let instructions):
///         print("System: \(instructions.content)")
///     case .toolCall(let call):
///         print("Tool: \(call.toolName)")
///     case .toolOutput(let output):
///         print("Tool Output: \(output.content)")
///     }
/// }
/// ```
public struct SessionTranscript: Sendable, Equatable {
    // MARK: - Properties

    /// All entries in the transcript, in chronological order.
    public let entries: [TranscriptEntry]

    /// The number of entries in the transcript.
    public var count: Int {
        entries.count
    }

    /// Whether the transcript is empty.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    /// The first entry in the transcript, if any.
    public var first: TranscriptEntry? {
        entries.first
    }

    /// The last entry in the transcript, if any.
    public var last: TranscriptEntry? {
        entries.last
    }

    // MARK: - Computed Properties

    /// All prompt entries in the transcript.
    public var prompts: [TranscriptPrompt] {
        entries.compactMap { entry in
            if case let .prompt(prompt) = entry { return prompt }
            return nil
        }
    }

    /// All response entries in the transcript.
    public var responses: [TranscriptResponse] {
        entries.compactMap { entry in
            if case let .response(response) = entry { return response }
            return nil
        }
    }

    /// All tool call entries in the transcript.
    public var toolCalls: [TranscriptToolCall] {
        entries.compactMap { entry in
            if case let .toolCall(call) = entry { return call }
            return nil
        }
    }

    // MARK: - Initialization

    /// Create an empty transcript.
    public init() {
        entries = []
    }

    /// Create a transcript with the given entries.
    /// - Parameter entries: The entries to include in the transcript.
    public init(entries: [TranscriptEntry]) {
        self.entries = entries
    }

    // MARK: - Subscript

    /// Access an entry by index.
    public subscript(index: Int) -> TranscriptEntry {
        entries[index]
    }
}

// MARK: - TranscriptEntry

/// An entry in a session transcript.
public enum TranscriptEntry: Sendable, Equatable, Identifiable {
    /// Instructions provided to the model.
    case instructions(TranscriptInstructions)

    /// A prompt from the user.
    case prompt(TranscriptPrompt)

    /// A response from the model.
    case response(TranscriptResponse)

    /// A tool call made by the model.
    case toolCall(TranscriptToolCall)

    /// Output from a tool execution.
    case toolOutput(TranscriptToolOutput)

    /// Unique identifier for the entry.
    public var id: String {
        switch self {
        case let .instructions(instructions): instructions.id
        case let .prompt(prompt): prompt.id
        case let .response(response): response.id
        case let .toolCall(toolCall): toolCall.id
        case let .toolOutput(toolOutput): toolOutput.id
        }
    }
}

// MARK: - Entry Types

/// Instructions provided to define the model's behavior.
public struct TranscriptInstructions: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier.
    public let id: String

    /// The instruction content.
    public let content: String

    /// When the instructions were set.
    public let timestamp: Date

    public init(id: String = UUID().uuidString,
                content: String,
                timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}

/// A prompt from the user to the model.
public struct TranscriptPrompt: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier.
    public let id: String

    /// The prompt content.
    public let content: String

    /// When the prompt was sent.
    public let timestamp: Date

    public init(id: String = UUID().uuidString,
                content: String,
                timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}

/// A response from the model.
public struct TranscriptResponse: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier.
    public let id: String

    /// The response content.
    public let content: String

    /// When the response was received.
    public let timestamp: Date

    /// Whether the response is complete.
    public let isComplete: Bool

    public init(id: String = UUID().uuidString,
                content: String,
                timestamp: Date = Date(),
                isComplete: Bool = true) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isComplete = isComplete
    }
}

/// A tool call made by the model.
public struct TranscriptToolCall: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier.
    public let id: String

    /// Name of the tool that was called.
    public let toolName: String

    /// Arguments passed to the tool.
    public let arguments: [String: String]

    /// When the tool was called.
    public let timestamp: Date

    public init(id: String = UUID().uuidString,
                toolName: String,
                arguments: [String: String],
                timestamp: Date = Date()) {
        self.id = id
        self.toolName = toolName
        self.arguments = arguments
        self.timestamp = timestamp
    }
}

/// Output from a tool execution.
public struct TranscriptToolOutput: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier.
    public let id: String

    /// The tool call ID this output responds to.
    public let toolCallId: String

    /// The output content.
    public let content: String

    /// When the output was produced.
    public let timestamp: Date

    public init(id: String = UUID().uuidString,
                toolCallId: String,
                content: String,
                timestamp: Date = Date()) {
        self.id = id
        self.toolCallId = toolCallId
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Collection Conformance

extension SessionTranscript: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = TranscriptEntry

    public var startIndex: Int {
        entries.startIndex
    }

    public var endIndex: Int {
        entries.endIndex
    }

    public func index(after index: Int) -> Int {
        entries.index(after: index)
    }

    public func index(before index: Int) -> Int {
        entries.index(before: index)
    }
}

// MARK: - Codable Conformance

extension SessionTranscript: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decode([TranscriptEntry].self, forKey: .entries)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
    }

    private enum CodingKeys: String, CodingKey {
        case entries
    }
}

extension TranscriptEntry: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "instructions":
            self = try .instructions(container.decode(TranscriptInstructions.self, forKey: .value))
        case "prompt":
            self = try .prompt(container.decode(TranscriptPrompt.self, forKey: .value))
        case "response":
            self = try .response(container.decode(TranscriptResponse.self, forKey: .value))
        case "toolCall":
            self = try .toolCall(container.decode(TranscriptToolCall.self, forKey: .value))
        case "toolOutput":
            self = try .toolOutput(container.decode(TranscriptToolOutput.self, forKey: .value))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown entry type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .instructions(value):
            try container.encode("instructions", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .prompt(value):
            try container.encode("prompt", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .response(value):
            try container.encode("response", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .toolCall(value):
            try container.encode("toolCall", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .toolOutput(value):
            try container.encode("toolOutput", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
}
