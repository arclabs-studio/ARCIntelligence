//
//  FoundationModelsProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Provider implementation for Apple Foundation Models (iOS 18.0+).
///
/// This provider uses on-device AI models for maximum privacy and zero latency.
/// Requires iOS 18.0+ and appropriate entitlements.
///
/// - Note: Foundation Models API is subject to change as Apple finalizes the API.
/// - Important: Not all devices support all Foundation Models capabilities.
public final class FoundationModelsProvider: IntelligenceProvider, ConversationProvider, Sendable {

    // MARK: - Properties

    public let id = "com.arclabs.intelligence.foundation"
    public let displayName = "Apple Foundation Models"
    public let version = "1.0"

    private let configuration: FoundationModelsConfiguration

    // MARK: - Initialization

    public init(configuration: FoundationModelsConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        if #available(iOS 18.0, macOS 15.0, *) {
            // TODO: Implement actual capability check when API is finalized
            // This should check device capabilities, model availability, etc.
            return true
        }
        return false
    }

    public func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        guard await isAvailable() else {
            throw IntelligenceError.providerUnavailable
        }

        // TODO: Implement actual Foundation Models API call
        // For now, throw a clear error indicating this needs implementation
        throw IntelligenceError.requestFailed(
            "Foundation Models API implementation pending Apple's final API documentation"
        )
    }

    public func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard await isAvailable() else {
                        throw IntelligenceError.providerUnavailable
                    }

                    // TODO: Implement streaming when API is available
                    continuation.finish(throwing: IntelligenceError.requestFailed(
                        "Streaming not yet implemented for Foundation Models"
                    ))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - ConversationProvider

    public func sendMessage(
        _ message: Message,
        in conversation: Conversation
    ) async throws -> Message {
        // Build prompt from conversation history
        let prompt = buildPrompt(from: conversation, adding: message)

        // Get completion
        let response = try await complete(
            prompt: prompt,
            configuration: CompletionConfiguration(
                temperature: configuration.defaultTemperature,
                systemPrompt: conversation.systemPrompt
            )
        )

        return Message(
            role: .assistant,
            content: response.content,
            metadata: ["tokens": "\(response.tokensUsed)"]
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
        // Rough estimation: ~4 characters per token
        let totalChars = conversation.messages.reduce(0) { $0 + $1.content.count }
        return totalChars / 4
    }

    // MARK: - Private Helpers

    private func buildPrompt(from conversation: Conversation, adding message: Message) -> String {
        var prompt = ""

        if let systemPrompt = conversation.systemPrompt {
            prompt += "System: \(systemPrompt)\n\n"
        }

        for msg in conversation.messages {
            prompt += "\(msg.role.rawValue.capitalized): \(msg.content)\n"
        }

        prompt += "\(message.role.rawValue.capitalized): \(message.content)\n"
        prompt += "Assistant:"

        return prompt
    }
}
