//
//  FoundationModelsProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Provider implementation for Apple Foundation Models (iOS 26.0+, macOS 26.0+, visionOS 26.0+).
///
/// This provider uses on-device AI models powered by Apple Intelligence for maximum
/// privacy and low latency. The on-device model supports text generation and understanding
/// with a context window of up to 4096 tokens.
///
/// ## Requirements
/// - iOS 26.0+, macOS 26.0+, or visionOS 26.0+
/// - Device must support Apple Intelligence
/// - Apple Intelligence must be enabled in Settings
///
/// ## Usage
/// ```swift
/// let provider = ARCIntelligence.foundationModels()
///
/// // Check availability first
/// let availability = await provider.checkAvailability()
/// guard availability.isAvailable else {
///     // Handle unavailability
///     return
/// }
///
/// // Generate a response
/// let response = try await provider.complete(
///     prompt: "Write a haiku about Swift",
///     configuration: .default
/// )
/// ```
///
/// - Note: The Foundation Models framework is only available on iOS 26+, macOS 26+, and visionOS 26+.
/// - Important: Not all devices support Apple Intelligence. Always check availability before use.
public final class FoundationModelsProvider: IntelligenceProvider, ConversationProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.foundation"
    public let displayName = "Apple Foundation Models"
    public let version = "1.0"

    let configuration: FoundationModelsConfiguration
    let logger = ARCLogger(
        subsystem: "com.arclabs.intelligence",
        category: "FoundationModels"
    )

    // MARK: - Initialization

    public init(configuration: FoundationModelsConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Availability

    /// Check detailed availability of the Foundation Models.
    ///
    /// - Returns: The availability status with detailed reason if unavailable.
    public func checkAvailability() async -> ModelAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                logger.debug("Foundation Models available")
                return .available

            case .unavailable(.deviceNotEligible):
                logger.info("Device not eligible for Apple Intelligence")
                return .unavailable(.deviceNotEligible)

            case .unavailable(.appleIntelligenceNotEnabled):
                logger.info("Apple Intelligence not enabled in Settings")
                return .unavailable(.appleIntelligenceNotEnabled)

            case .unavailable(.modelNotReady):
                logger.info("Model not ready (downloading or initializing)")
                return .unavailable(.modelNotReady)

            case .unavailable:
                logger.info("Model unavailable for unknown reason")
                return .unavailable(.unknown("Model unavailable"))

            @unknown default:
                logger.warning("Unknown availability status")
                return .unavailable(.unknown("Unknown availability status"))
            }
        } else {
            logger.info("Platform does not meet minimum requirements (iOS 26+)")
            return .unavailable(.unsupportedPlatform)
        }
        #else
        logger.info("FoundationModels framework not available on this platform")
        return .unavailable(.unsupportedPlatform)
        #endif
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        let availability = await checkAvailability()
        return availability.isAvailable
    }

    public func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        logger.debug("Starting completion request", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "temperature": .public("\(configuration.temperature)")
        ])

        let availability = await checkAvailability()
        guard availability.isAvailable else {
            logger.warning("Provider unavailable for completion request")
            if let error = availability.toError() {
                throw error
            }
            throw IntelligenceError.providerUnavailable
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return try await performCompletion(prompt: prompt, configuration: configuration)
        }
        #endif

        throw IntelligenceError.providerUnavailable
    }

    public func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        logger.debug("Starting streaming completion request", metadata: [
            "promptLength": .public("\(prompt.count)")
        ])

        return AsyncThrowingStream { [self] continuation in
            Task {
                do {
                    let availability = await checkAvailability()
                    guard availability.isAvailable else {
                        logger.warning("Provider unavailable for streaming request")
                        if let error = availability.toError() {
                            throw error
                        }
                        throw IntelligenceError.providerUnavailable
                    }

                    #if canImport(FoundationModels)
                    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                        try await performStreamingCompletion(
                            prompt: prompt,
                            configuration: configuration,
                            continuation: continuation
                        )
                        return
                    }
                    #endif

                    throw IntelligenceError.providerUnavailable
                } catch {
                    logger.error("Streaming request failed", metadata: [
                        "error": .public(error.localizedDescription)
                    ])
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
        logger.debug("Sending message in conversation", metadata: [
            "conversationId": .public(conversation.id.uuidString),
            "messageRole": .public(message.role.rawValue),
            "historyCount": .public("\(conversation.messages.count)")
        ])

        // Build prompt from conversation history
        let prompt = buildPrompt(from: conversation, adding: message)

        // Get completion with conversation's system prompt as instructions
        let completionConfig = CompletionConfiguration(
            temperature: configuration.defaultTemperature,
            systemPrompt: conversation.systemPrompt ?? configuration.defaultInstructions
        )

        let response = try await complete(
            prompt: prompt,
            configuration: completionConfig
        )

        logger.info("Message sent successfully", metadata: [
            "tokensUsed": .public("\(response.tokensUsed)")
        ])

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
        // Apple's model uses approximately 3-4 characters per token for English
        // and 1 character per token for CJK languages
        let totalChars = conversation.messages.reduce(0) { $0 + $1.content.count }
        let systemChars = conversation.systemPrompt?.count ?? 0
        return (totalChars + systemChars) / 4
    }

    // MARK: - Private Implementation

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func performCompletion(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        do {
            // Create session with instructions if provided
            let session = if let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions {
                LanguageModelSession(instructions: systemPrompt)
            } else {
                LanguageModelSession()
            }

            // Configure generation options
            let options = GenerationOptions(temperature: Double(configuration.temperature))

            // Perform the request
            let response = try await session.respond(to: prompt, options: options)

            logger.info("Completion successful", metadata: [
                "responseLength": .public("\(response.content.count)")
            ])

            return IntelligenceResponse(
                content: response.content,
                tokensUsed: estimateTokenCount(response.content),
                finishReason: .completed,
                metadata: [:]
            )
        } catch {
            throw mapFoundationModelsError(error)
        }
    }

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func performStreamingCompletion(
        prompt: String,
        configuration: CompletionConfiguration,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        do {
            // Create session with instructions if provided
            let session = if let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions {
                LanguageModelSession(instructions: systemPrompt)
            } else {
                LanguageModelSession()
            }

            // Configure generation options
            let options = GenerationOptions(temperature: Double(configuration.temperature))

            // Stream the response
            let stream = session.streamResponse(to: prompt, options: options)

            for try await partialResponse in stream {
                continuation.yield(partialResponse.content)
            }

            continuation.finish()
            logger.info("Streaming completion finished successfully")
        } catch {
            throw mapFoundationModelsError(error)
        }
    }

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    // swiftlint:disable:next cyclomatic_complexity
    func mapFoundationModelsError(_ error: Error) -> IntelligenceError {
        // Map Apple's specific errors to our error types
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case let .guardrailViolation(details):
                logger.warning("Guardrail violation", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .guardrailViolation(String(describing: details))

            case let .refusal(refusal, _):
                logger.info("Model refused request")
                return .modelRefusal(String(describing: refusal))

            case let .exceededContextWindowSize(details):
                logger.warning("Context window exceeded", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .contextWindowExceeded(used: 0, limit: 4096)

            case let .assetsUnavailable(details):
                logger.error("Model assets unavailable", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .modelNotReady

            case let .unsupportedGuide(details):
                logger.error("Unsupported generation guide", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .invalidRequest("Unsupported generation guide: \(details)")

            case let .unsupportedLanguageOrLocale(details):
                logger.warning("Unsupported language or locale", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .invalidRequest("Unsupported language or locale: \(details)")

            case let .decodingFailure(details):
                logger.error("Response decoding failed", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .responseParseFailed(String(describing: details))

            case let .rateLimited(details):
                logger.warning("Rate limited", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .rateLimitExceeded

            case let .concurrentRequests(details):
                logger.warning("Concurrent request limit exceeded", metadata: [
                    "details": .public(String(describing: details))
                ])
                return .requestFailed("Too many concurrent requests: \(details)")

            @unknown default:
                logger.error("Unknown generation error", metadata: [
                    "error": .public(error.localizedDescription)
                ])
                return .requestFailed(error.localizedDescription)
            }
        }

        logger.error("Request failed", metadata: [
            "error": .public(error.localizedDescription)
        ])
        return .requestFailed(error.localizedDescription)
    }
    #endif

    private func buildPrompt(from conversation: Conversation, adding message: Message) -> String {
        var components: [String] = []

        // Add conversation history
        for msg in conversation.messages {
            components.append("\(msg.role.rawValue.capitalized): \(msg.content)")
        }

        // Add new message
        components.append("\(message.role.rawValue.capitalized): \(message.content)")

        return components.joined(separator: "\n")
    }

    private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token for English
        text.count / 4
    }
}
