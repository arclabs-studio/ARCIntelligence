//
//  FoundationModelsProvider+Prewarm.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCLogger
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Prewarm Support

extension FoundationModelsProvider {
    /// Preloads the model resources into memory to reduce initial response latency.
    ///
    /// Call this method before your first generation request to ensure the model
    /// is ready and can respond with minimal delay. This is especially useful for:
    /// - Apps that need immediate AI responses on launch
    /// - Time-sensitive interactions where latency matters
    /// - Preloading during app idle time
    ///
    /// ## Example
    /// ```swift
    /// let provider = ARCIntelligence.foundationModels()
    ///
    /// // Prewarm during app launch
    /// provider.prewarm()
    ///
    /// // Later, responses will be faster
    /// let response = try await provider.complete(
    ///     prompt: "Hello!",
    ///     configuration: .default
    /// )
    /// ```
    ///
    /// - Note: On platforms without Foundation Models support, this method does nothing.
    /// - Note: Calling this method doesn't guarantee immediate loading if the app
    ///   is in the background or the system is under load.
    public func prewarm() {
        logger.debug("Prewarming Foundation Models")

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let session = LanguageModelSession()
            session.prewarm()
            logger.info("Foundation Models prewarm requested")
        }
        #endif
    }

    /// Preloads the model with a prompt prefix to reduce latency for specific use cases.
    ///
    /// Use this variant when you know the beginning of your prompts in advance.
    /// The model will cache this prefix, making subsequent requests that start
    /// with this text significantly faster.
    ///
    /// ## Example
    /// ```swift
    /// let provider = ARCIntelligence.foundationModels()
    ///
    /// // Prewarm with a common prompt prefix
    /// provider.prewarm(promptPrefix: "You are a helpful assistant. ")
    ///
    /// // Requests starting with this prefix will be faster
    /// let response = try await provider.complete(
    ///     prompt: "You are a helpful assistant. Help me with...",
    ///     configuration: .default
    /// )
    /// ```
    ///
    /// - Parameter promptPrefix: A prefix string to cache for faster subsequent requests.
    /// - Note: On platforms without Foundation Models support, this method does nothing.
    /// - Note: Calling this method doesn't guarantee immediate loading if the app
    ///   is in the background or the system is under load.
    public func prewarm(promptPrefix: String) {
        logger.debug("Prewarming Foundation Models with prompt prefix",
                     metadata: ["prefixLength": .public("\(promptPrefix.count)")])

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let session = if let instructions = configuration.defaultInstructions {
                LanguageModelSession(instructions: instructions)
            } else {
                LanguageModelSession()
            }
            let prompt = Prompt(promptPrefix)
            session.prewarm(promptPrefix: prompt)
            logger.info("Foundation Models prewarm with prefix requested")
        }
        #endif
    }

    /// Preloads the model with the provider's default instructions.
    ///
    /// This combines prewarming with the default instructions from the configuration,
    /// which is ideal when you always use the same system prompt.
    ///
    /// ## Example
    /// ```swift
    /// let config = FoundationModelsConfiguration(
    ///     defaultInstructions: "You are a cooking assistant."
    /// )
    /// let provider = ARCIntelligence.foundationModels(configuration: config)
    ///
    /// // Prewarm with the configured instructions
    /// provider.prewarmWithInstructions()
    /// ```
    ///
    /// - Note: If no default instructions are configured, this behaves like `prewarm()`.
    public func prewarmWithInstructions() {
        if let instructions = configuration.defaultInstructions {
            prewarm(promptPrefix: instructions)
        } else {
            prewarm()
        }
    }
}
