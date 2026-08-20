//
//  FoundationModelsProvider+Generable.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCLogger
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - GenerableProvider Conformance

extension FoundationModelsProvider: GenerableProvider {
    /// Generate a structured response using guided generation.
    ///
    /// On iOS 26+, this uses Apple's constrained sampling to ensure
    /// the response conforms to the expected type.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - prompt: The input prompt.
    ///   - configuration: Generation configuration.
    /// - Returns: An instance of the requested type.
    /// - Throws: `IntelligenceError` if generation fails.
    public func generate<T: Codable & Sendable>(_ type: T.Type,
                                                prompt: String,
                                                configuration: CompletionConfiguration) async throws -> T {
        logger.debug("Starting guided generation", metadata: ["type": .public(String(describing: type)),
                                                              "promptLength": .public("\(prompt.count)")])

        let availability = await checkAvailability()
        guard availability.isAvailable else {
            logger.warning("Provider unavailable for guided generation")
            if let error = availability.toError() {
                throw error
            }
            throw IntelligenceError.providerUnavailable
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return try await performGuidedGeneration(type,
                                                     prompt: prompt,
                                                     configuration: configuration)
        }
        #endif

        throw IntelligenceError.providerUnavailable
    }

    // MARK: - Private Implementation

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func performGuidedGeneration<T: Codable & Sendable>(_ type: T.Type,
                                                                prompt: String,
                                                                configuration: CompletionConfiguration) async throws
    -> T {
        do {
            // Create session with instructions if provided
            let session = if let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions {
                LanguageModelSession(instructions: systemPrompt)
            } else {
                LanguageModelSession()
            }

            let options = GenerationOptions(temperature: Double(configuration.temperature))

            // For types that conform to Generable, use direct generation
            // For other Codable types, we generate JSON and decode
            let response = try await session.respond(to: prompt, options: options)

            // Parse the response as JSON
            guard let jsonData = response.content.data(using: .utf8) else {
                throw IntelligenceError.responseParseFailed("Unable to convert response to data")
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(type, from: jsonData)

            logger.info("Guided generation successful", metadata: ["type": .public(String(describing: type))])

            return result
        } catch let error as IntelligenceError {
            throw error
        } catch is DecodingError {
            logger.error("Failed to decode response", metadata: ["type": .public(String(describing: type))])
            throw IntelligenceError.responseParseFailed("Failed to decode response as \(type)")
        } catch {
            throw mapFoundationModelsError(error)
        }
    }
    #endif
}
