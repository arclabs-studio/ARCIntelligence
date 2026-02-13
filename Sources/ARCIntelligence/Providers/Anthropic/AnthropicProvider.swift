//
//  AnthropicProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import ARCLogger
import Foundation

/// Provider implementation for Anthropic Claude API.
///
/// Supports Claude Haiku, Sonnet, and Opus models via the Anthropic Messages API.
/// Works on iOS 17+ (no Apple Intelligence dependency).
///
/// ## Features
/// - Text completion and streaming
/// - Multi-turn conversations
/// - Tool calling (via `ToolProvider`)
/// - Structured output generation (via `GenerableProvider`)
///
/// ## Usage
/// ```swift
/// // Quick setup
/// let provider = ARCIntelligence.anthropic(apiKey: "sk-ant-...")
///
/// // Check availability (validates API key is set)
/// let available = await provider.isAvailable()
///
/// // Generate a response
/// let response = try await provider.complete(
///     prompt: "Explain quantum computing",
///     configuration: .default
/// )
/// ```
///
/// - Important: Do not ship API keys in client apps. Use AIProxy authentication
///   for production deployments.
public final class AnthropicProvider: Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.anthropic"
    public let displayName = "Anthropic Claude"
    public let version = "1.0"

    let configuration: AnthropicConfiguration
    let apiClient: AnthropicAPIClient
    let logger = ARCLogger(
        subsystem: "com.arclabs.intelligence",
        category: "Anthropic"
    )

    // MARK: - Initialization

    /// Create a provider with the given configuration.
    /// - Parameter configuration: The Anthropic provider configuration.
    public init(configuration: AnthropicConfiguration) {
        self.configuration = configuration
        apiClient = AnthropicHTTPClient(authentication: configuration.authentication)
    }

    /// Internal initializer for testing with a mock API client.
    init(configuration: AnthropicConfiguration, apiClient: AnthropicAPIClient) {
        self.configuration = configuration
        self.apiClient = apiClient
    }
}

// MARK: - IntelligenceProvider

extension AnthropicProvider: IntelligenceProvider {
    public func isAvailable() async -> Bool {
        switch configuration.authentication {
        case let .apiKey(key):
            !key.isEmpty
        case let .aiProxy(partialKey, serviceURL):
            !partialKey.isEmpty && !serviceURL.isEmpty
        }
    }

    public func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        logger.debug("Starting completion request", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "model": .public(self.configuration.model.modelId)
        ])

        let request = buildRequest(prompt: prompt, configuration: configuration)
        let response = try await apiClient.sendMessage(request)

        logger.info("Completion successful", metadata: [
            "inputTokens": .public("\(response.usage.inputTokens)"),
            "outputTokens": .public("\(response.usage.outputTokens)")
        ])

        return mapResponse(response)
    }

    public func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        logger.debug("Starting streaming completion", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "model": .public(self.configuration.model.modelId)
        ])

        let request = buildRequest(prompt: prompt, configuration: configuration, stream: true)

        return AsyncThrowingStream { [apiClient, logger] continuation in
            Task {
                do {
                    let eventStream = apiClient.streamMessage(request)

                    for try await event in eventStream {
                        switch event {
                        case let .contentBlockDelta(_, text):
                            continuation.yield(text)
                        case .messageStop:
                            continuation.finish()
                            return
                        default:
                            break
                        }
                    }

                    continuation.finish()
                } catch {
                    logger.error("Streaming failed", metadata: [
                        "error": .public(error.localizedDescription)
                    ])
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - ConversationProvider

extension AnthropicProvider: ConversationProvider {
    public func sendMessage(
        _ message: Message,
        in conversation: Conversation
    ) async throws -> Message {
        logger.debug("Sending message in conversation", metadata: [
            "conversationId": .public(conversation.id.uuidString),
            "historyCount": .public("\(conversation.messages.count)")
        ])

        let completionConfig = CompletionConfiguration(
            temperature: configuration.defaultTemperature,
            maxTokens: configuration.defaultMaxTokens,
            systemPrompt: conversation.systemPrompt ?? configuration.defaultInstructions
        )

        let request = buildConversationRequest(
            conversation: conversation,
            newMessage: message,
            configuration: completionConfig
        )

        let response = try await apiClient.sendMessage(request)
        let mapped = mapResponse(response)

        logger.info("Message sent successfully", metadata: [
            "tokensUsed": .public("\(mapped.tokensUsed)")
        ])

        return Message(
            role: .assistant,
            content: mapped.content,
            metadata: [
                "tokens": "\(mapped.tokensUsed)",
                "model": configuration.model.modelId
            ]
        )
    }

    public func continueConversation(
        _ conversation: Conversation,
        with text: String
    ) async throws -> Message {
        let userMessage = Message(role: .user, content: text)
        return try await sendMessage(userMessage, in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        // Claude uses ~3.5 characters per token for English
        let totalChars = conversation.messages.reduce(0) { $0 + $1.content.count }
        let systemChars = conversation.systemPrompt?.count ?? 0
        return (totalChars + systemChars) * 10 / 35
    }
}
