//
//  MockFoundationModelsProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import ARCIntelligence
import Foundation

/// Mock replacement for `FoundationModelsProvider` that works offline and on any
/// simulator without requiring Apple Intelligence.
///
/// Conforms to every protocol that `FoundationModelsProvider` conforms to so it
/// can be dropped in as a test double in any test suite.
///
/// ## Usage
/// ```swift
/// // Basic completion
/// let mock = MockFoundationModelsProvider(response: "Hello, world!")
///
/// // Structured generation — supply valid JSON for the target type
/// let mock = MockFoundationModelsProvider(
///     jsonResponse: #"{"title": "Inception", "rating": 9}"#
/// )
///
/// // Content tagging
/// let mock = MockFoundationModelsProvider(
///     tagsToReturn: [ContentTag(value: "hiking", category: .topic)]
/// )
///
/// // Tool calling
/// let mock = MockFoundationModelsProvider(
///     toolResponse: "The weather is sunny",
///     toolCallsToSimulate: [
///         ToolCallRecord(toolName: "weather", arguments: [:], output: "Sunny", duration: 0.1)
///     ]
/// )
///
/// // Simulate failure
/// let mock = MockFoundationModelsProvider(shouldFail: true)
/// ```
public final class MockFoundationModelsProvider: IntelligenceProvider,
    ConversationProvider,
    GenerableProvider,
    ToolProvider,
    ContentTaggingProvider,
    Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.foundation"
    public let displayName = "Mock Foundation Models Provider"
    public let version = "1.0"

    private let response: String
    private let jsonResponse: String?
    private let tagsToReturn: [ContentTag]
    private let toolResponse: String
    private let toolCallsToSimulate: [ToolCallRecord]
    private let shouldFail: Bool
    private let simulatedDelay: TimeInterval
    private let errorToThrow: IntelligenceError?

    // MARK: - Initialization

    /// Create a mock Foundation Models provider.
    ///
    /// - Parameters:
    ///   - response: Text returned for `complete` and `streamComplete` calls.
    ///   - jsonResponse: JSON string decoded for `generate<T>` calls.
    ///   - tagsToReturn: Tags returned for `generateTags` calls.
    ///   - toolResponse: Text returned as the final response for tool-calling calls.
    ///   - toolCallsToSimulate: Tool call records included in tool-calling responses.
    ///   - shouldFail: When `true`, every call throws an error.
    ///   - simulatedDelay: Artificial delay added before each response.
    ///   - errorToThrow: Specific error to throw; defaults to `.requestFailed("Mock failure")`.
    public init(response: String = "Mock Foundation Models response",
                jsonResponse: String? = nil,
                tagsToReturn: [ContentTag] = [],
                toolResponse: String = "Mock tool response",
                toolCallsToSimulate: [ToolCallRecord] = [],
                shouldFail: Bool = false,
                simulatedDelay: TimeInterval = 0.0,
                errorToThrow: IntelligenceError? = nil) {
        self.response = response
        self.jsonResponse = jsonResponse
        self.tagsToReturn = tagsToReturn
        self.toolResponse = toolResponse
        self.toolCallsToSimulate = toolCallsToSimulate
        self.shouldFail = shouldFail
        self.simulatedDelay = simulatedDelay
        self.errorToThrow = errorToThrow
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt _: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        try await sleep()
        try throwIfNeeded()
        return IntelligenceResponse(content: response,
                                    tokensUsed: response.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt _: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [self] continuation in
            Task {
                do {
                    try await sleep()
                    try throwIfNeeded()
                    for char in response {
                        continuation.yield(String(char))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - ConversationProvider

    public func sendMessage(_ message: Message,
                            in _: Conversation) async throws -> Message {
        let reply = try await complete(prompt: message.content, configuration: .default)
        return Message(role: .assistant, content: reply.content)
    }

    public func continueConversation(_ conversation: Conversation,
                                     with text: String) async throws -> Message {
        try await sendMessage(Message(role: .user, content: text), in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        conversation.messages.reduce(0) { $0 + $1.content.count / 4 }
    }

    // MARK: - GenerableProvider

    public func generate<T: Codable & Sendable>(_ type: T.Type,
                                                prompt _: String,
                                                configuration _: CompletionConfiguration) async throws -> T {
        try await sleep()
        try throwIfNeeded()

        guard let json = jsonResponse else {
            throw IntelligenceError.responseParseFailed("No JSON response configured on MockFoundationModelsProvider")
        }

        do {
            return try JSONDecoder().decode(type, from: Data(json.utf8))
        } catch {
            throw IntelligenceError
                .responseParseFailed("Failed to decode \(type): \(error.localizedDescription)")
        }
    }

    // MARK: - ToolProvider

    public func respondWithToolCalls(to _: String,
                                     tools _: [any IntelligenceTool],
                                     configuration _: CompletionConfiguration) async throws
    -> (response: IntelligenceResponse, toolCalls: [ToolCallRecord]) {
        try await sleep()
        try throwIfNeeded()
        let intelligenceResponse = IntelligenceResponse(content: toolResponse,
                                                        tokensUsed: toolResponse.count / 4,
                                                        finishReason: .completed)
        return (intelligenceResponse, toolCallsToSimulate)
    }

    // MARK: - ContentTaggingProvider

    public func generateTags(for text: String,
                             categories _: [TagCategory],
                             maxTags: Int) async throws -> [ContentTag] {
        guard !text.isEmpty else {
            throw IntelligenceError.invalidRequest("Text cannot be empty")
        }
        try await sleep()
        try throwIfNeeded()
        return Array(tagsToReturn.prefix(maxTags))
    }

    // MARK: - Private Helpers

    private func sleep() async throws {
        if simulatedDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedDelay))
        }
    }

    private func throwIfNeeded() throws {
        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock failure")
        }
    }
}
