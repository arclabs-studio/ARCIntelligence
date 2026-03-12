//
//  OpenAIProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import ARCLogger
import Foundation

/// Provider implementation for the OpenAI Chat Completions API.
///
/// Supports GPT-4o, GPT-4o Mini, o3-mini and other OpenAI models.
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
/// let provider = ARCIntelligence.openAI(apiKey: "sk-...")
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
public final class OpenAIProvider: Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.openai"
    public let displayName = "OpenAI"
    public let version = "1.0"

    let configuration: OpenAIConfiguration
    let apiClient: OpenAICompatibleAPIClient
    let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                           category: "OpenAI")

    // MARK: - Constants

    private static let defaultBaseURL = URL(literal: "https://api.openai.com")

    // MARK: - Initialization

    /// Create a provider with the given configuration.
    /// - Parameter configuration: The OpenAI provider configuration.
    public init(configuration: OpenAIConfiguration) {
        self.configuration = configuration

        let baseURL: URL
        var headers = ["Content-Type": "application/json"]

        switch configuration.authentication {
        case let .apiKey(key):
            baseURL = Self.defaultBaseURL
            headers["Authorization"] = "Bearer \(key)"
        case let .aiProxy(partialKey, serviceURL):
            baseURL = URL(string: serviceURL) ?? Self.defaultBaseURL
            headers["Authorization"] = "Bearer \(partialKey)"
        }

        if let organization = configuration.organization {
            headers["OpenAI-Organization"] = organization
        }

        apiClient = OpenAICompatibleHTTPClient(baseURL: baseURL, authHeaders: headers)
    }

    /// Internal initializer for testing with a mock API client.
    init(configuration: OpenAIConfiguration, apiClient: OpenAICompatibleAPIClient) {
        self.configuration = configuration
        self.apiClient = apiClient
    }
}

// MARK: - IntelligenceProvider

extension OpenAIProvider: IntelligenceProvider {
    public func isAvailable() async -> Bool {
        switch configuration.authentication {
        case let .apiKey(key):
            !key.isEmpty
        case let .aiProxy(partialKey, serviceURL):
            !partialKey.isEmpty && !serviceURL.isEmpty
        }
    }

    public func complete(prompt: String,
                         configuration: CompletionConfiguration) async throws -> IntelligenceResponse {
        logger.debug("Starting completion request", metadata: ["promptLength": .public("\(prompt.count)"),
                                                               "model": .public(self.configuration.model.modelId)])

        let request = buildRequest(prompt: prompt, configuration: configuration)
        let response = try await apiClient.sendChatCompletion(request)

        // swiftlint:disable line_length
        logger.info("Completion successful", metadata: ["promptTokens": .public("\(response.usage?.promptTokens ?? 0)"),
                                                        "completionTokens": .public("\(response.usage?.completionTokens ?? 0)")])
        // swiftlint:enable line_length

        return mapResponse(response)
    }

    public func streamComplete(prompt: String,
                               configuration: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        logger.debug("Starting streaming completion", metadata: ["promptLength": .public("\(prompt.count)"),
                                                                 "model": .public(self.configuration.model.modelId)])

        let request = buildRequest(prompt: prompt, configuration: configuration, stream: true)

        return AsyncThrowingStream { [apiClient, logger] continuation in
            Task {
                do {
                    let chunkStream = apiClient.streamChatCompletion(request)

                    for try await chunk in chunkStream {
                        if let content = chunk.choices?.first?.delta.content {
                            continuation.yield(content)
                        }

                        if let finishReason = chunk.choices?.first?.finishReason, finishReason == "stop" {
                            continuation.finish()
                            return
                        }
                    }

                    continuation.finish()
                } catch {
                    logger.error("Streaming failed", metadata: ["error": .public(error.localizedDescription)])
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - ConversationProvider

extension OpenAIProvider: ConversationProvider {
    public func sendMessage(_ message: Message,
                            in conversation: Conversation) async throws -> Message {
        logger.debug("Sending message in conversation",
                     metadata: ["conversationId": .public(conversation.id.uuidString),
                                "historyCount": .public("\(conversation.messages.count)")])

        let completionConfig = CompletionConfiguration(temperature: configuration.defaultTemperature,
                                                       maxTokens: configuration.defaultMaxTokens,
                                                       systemPrompt: conversation.systemPrompt ?? configuration
                                                           .defaultInstructions)

        let request = buildConversationRequest(conversation: conversation,
                                               newMessage: message,
                                               configuration: completionConfig)

        let response = try await apiClient.sendChatCompletion(request)
        let mapped = mapResponse(response)

        logger.info("Message sent successfully", metadata: ["tokensUsed": .public("\(mapped.tokensUsed)")])

        return Message(role: .assistant,
                       content: mapped.content,
                       metadata: ["tokens": "\(mapped.tokensUsed)",
                                  "model": configuration.model.modelId])
    }

    public func continueConversation(_ conversation: Conversation,
                                     with text: String) async throws -> Message {
        let userMessage = Message(role: .user, content: text)
        return try await sendMessage(userMessage, in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        // OpenAI models use ~4 characters per token for English
        let totalChars = conversation.messages.reduce(0) { $0 + $1.content.count }
        let systemChars = conversation.systemPrompt?.count ?? 0
        return (totalChars + systemChars) / 4
    }
}

// MARK: - OpenAICompatibleProvider

extension OpenAIProvider: OpenAICompatibleProvider {
    var providerDefaults: OpenAICompatibleMapping.ProviderDefaults {
        OpenAICompatibleMapping.ProviderDefaults(modelId: configuration.model.modelId,
                                                 defaultInstructions: configuration.defaultInstructions,
                                                 defaultMaxTokens: configuration.defaultMaxTokens)
    }

    var maxToolRounds: Int {
        configuration.maxToolRounds
    }
}
