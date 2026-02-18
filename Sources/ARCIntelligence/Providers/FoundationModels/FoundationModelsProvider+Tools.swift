//
//  FoundationModelsProvider+Tools.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCLogger
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - ToolProvider Conformance

extension FoundationModelsProvider: ToolProvider {
    /// Generate a response using the provided tools.
    ///
    /// On iOS 26+, this uses Apple's tool calling API where the model
    /// can decide to call tools to gather information or perform actions.
    ///
    /// - Parameters:
    ///   - prompt: The input prompt.
    ///   - tools: Available tools for the model to use.
    ///   - configuration: Generation configuration.
    /// - Returns: Response and tool call records.
    /// - Throws: `IntelligenceError` if generation fails.
    public func respondWithToolCalls(to prompt: String,
                                     tools: [any IntelligenceTool],
                                     configuration: CompletionConfiguration) async throws
        -> (response: IntelligenceResponse,
            toolCalls: [ToolCallRecord]) {
        logger.debug("Starting tool-assisted generation", metadata: [
            "promptLength": .public("\(prompt.count)"),
            "toolCount": .public("\(tools.count)")
        ])

        let availability = await checkAvailability()
        guard availability.isAvailable else {
            logger.warning("Provider unavailable for tool calling")
            if let error = availability.toError() {
                throw error
            }
            throw IntelligenceError.providerUnavailable
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return try await performToolAssistedGeneration(prompt: prompt,
                                                           tools: tools,
                                                           configuration: configuration)
        }
        #endif

        throw IntelligenceError.providerUnavailable
    }

    // MARK: - Private Implementation

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func performToolAssistedGeneration(prompt: String,
                                               tools: [any IntelligenceTool],
                                               configuration: CompletionConfiguration) async throws
        -> (response: IntelligenceResponse,
            toolCalls: [ToolCallRecord]) {
        do {
            // Wrap our tools in Apple's Tool protocol
            let appleTools = tools.map { FoundationModelToolWrapper(tool: $0) }

            // Create session with tools
            let session = if let systemPrompt = configuration.systemPrompt ?? self.configuration.defaultInstructions {
                LanguageModelSession(tools: appleTools, instructions: systemPrompt)
            } else {
                LanguageModelSession(tools: appleTools)
            }

            let options = GenerationOptions(temperature: Double(configuration.temperature))

            // Perform the request - Apple's framework handles tool calling automatically
            let response = try await session.respond(to: prompt, options: options)

            // Tool calls are handled internally by Apple's framework
            // We return an empty array as the calls are already processed
            let toolCalls: [ToolCallRecord] = []

            logger.info("Tool-assisted generation successful",
                        metadata: ["responseLength": .public("\(response.content.count)")])

            let intelligenceResponse = IntelligenceResponse(content: response.content,
                                                            tokensUsed: response.content.count / 4,
                                                            finishReason: .completed,
                                                            metadata: [:])

            return (intelligenceResponse, toolCalls)
        } catch let error as IntelligenceError {
            throw error
        } catch {
            throw mapFoundationModelsError(error)
        }
    }
    #endif
}

// MARK: - Apple Tool Wrapper

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private struct FoundationModelToolWrapper: Tool {
    let wrappedTool: any IntelligenceTool

    var name: String {
        wrappedTool.name
    }

    var description: String {
        wrappedTool.description
    }

    @Generable
    struct Arguments {
        var jsonArguments: String
    }

    init(tool: any IntelligenceTool) {
        wrappedTool = tool
    }

    func call(arguments: Arguments) async throws -> String {
        // Parse JSON arguments to dictionary
        let parsedArgs = parseJSONArguments(arguments.jsonArguments)
        return try await wrappedTool.execute(arguments: parsedArgs)
    }

    private func parseJSONArguments(_ json: String) -> [String: ToolArgumentValue] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: ToolArgumentValue].self, from: data)
        else {
            return [:]
        }
        return dict
    }
}
#endif
