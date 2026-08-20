//
//  GeminiProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import ARCLogger
import Foundation

/// Provider implementation for the Google Gemini API.
///
/// Calls Google's native `v1` Gemini REST API directly at
/// `generativelanguage.googleapis.com`. This is **distinct from** `ARCFirebaseAI`,
/// which routes through Firebase AI Logic. Use both for resilience: when
/// Firebase reports model overload, fall back to this direct provider.
///
/// For production apps, use AIProxy authentication so API keys are never
/// bundled in the binary.
///
/// ## Features
/// - Text completion and streaming
/// - Multi-turn conversations
/// - Tool calling (via `ToolProvider`)
/// - Structured output generation (via `GenerableProvider`)
///
/// ## Usage
/// ```swift
/// // Quick setup (development only)
/// let provider = ARCIntelligence.gemini(apiKey: "AIza...")
///
/// // Check availability (validates API key is set)
/// let available = await provider.isAvailable()
///
/// // Generate a response
/// let response = try await provider.complete(
///     prompt: "Explain gradient descent",
///     configuration: .default
/// )
/// ```
///
/// - Important: Do not ship API keys in client apps. Use AIProxy authentication
///   for production deployments.
public final class GeminiProvider: Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.gemini"
    public let displayName = "Google Gemini"
    public let version = "1.0"

    let configuration: GeminiConfiguration
    let apiClient: GeminiAPIClient
    let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                           category: "Gemini")

    // MARK: - Initialization

    /// Create a provider with the given configuration.
    /// - Parameter configuration: The Gemini provider configuration.
    public init(configuration: GeminiConfiguration) {
        self.configuration = configuration
        apiClient = GeminiHTTPClient(authentication: configuration.authentication)
    }

    /// Internal initializer for testing with a mock API client.
    init(configuration: GeminiConfiguration, apiClient: GeminiAPIClient) {
        self.configuration = configuration
        self.apiClient = apiClient
    }
}

// MARK: - IntelligenceProvider

extension GeminiProvider: IntelligenceProvider {
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
        let response = try await apiClient.generateContent(request)

        let mapped = mapResponse(response)
        logger.info("Completion successful", metadata: ["tokensUsed": .public("\(mapped.tokensUsed)")])

        return mapped
    }

    public func streamComplete(prompt: String,
                               configuration: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        logger.debug("Starting streaming completion", metadata: ["promptLength": .public("\(prompt.count)"),
                                                                 "model": .public(self.configuration.model.modelId)])

        let request = buildRequest(prompt: prompt, configuration: configuration)

        return AsyncThrowingStream { [apiClient, logger] continuation in
            Task {
                do {
                    let chunkStream = apiClient.streamGenerateContent(request)

                    for try await chunk in chunkStream {
                        // Yield text from each part in the first candidate
                        let text = chunk.candidates?.first?.content?.parts
                            .compactMap { part -> String? in
                                if case let .text(text) = part {
                                    return text
                                }
                                return nil
                            }
                            .joined() ?? ""

                        if !text.isEmpty {
                            continuation.yield(text)
                        }

                        if let finishReason = chunk.candidates?.first?.finishReason,
                           !finishReason.isEmpty {
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

extension GeminiProvider: ConversationProvider {
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

        let response = try await apiClient.generateContent(request)
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
        // Gemini uses ~4 characters per token for English
        let totalChars = conversation.messages.reduce(0) { $0 + $1.content.count }
        let systemChars = conversation.systemPrompt?.count ?? 0
        return (totalChars + systemChars) / 4
    }
}
