//
//  MockToolProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import ARCIntelligence
import Foundation

/// Mock implementation of `ToolProvider` for testing.
///
/// Allows configuring tool call behavior and responses for testing
/// tool-assisted generation workflows.
///
/// ## Usage
/// ```swift
/// let mock = MockToolProvider(
///     response: "The weather is sunny",
///     toolCallsToSimulate: [
///         ToolCallRecord(
///             toolName: "getWeather",
///             arguments: ["city": "Boston"],
///             output: "72°F, Sunny",
///             duration: 0.5
///         )
///     ]
/// )
/// ```
public final class MockToolProvider: IntelligenceProvider, ToolProvider, Sendable {
    // MARK: - Properties

    public let id = "com.arclabs.intelligence.mock.tools"
    public let displayName = "Mock Tool Provider"
    public let version = "1.0"

    private let response: String
    private let toolCallsToSimulate: [ToolCallRecord]
    private let shouldFail: Bool
    private let shouldCallTools: Bool
    private let simulatedDelay: TimeInterval
    private let errorToThrow: IntelligenceError?

    // MARK: - Initialization

    /// Create a mock tool provider.
    ///
    /// - Parameters:
    ///   - response: The response content to return.
    ///   - toolCallsToSimulate: Tool calls to include in the response.
    ///   - shouldFail: Whether to simulate failure.
    ///   - shouldCallTools: Whether to actually call the provided tools.
    ///   - simulatedDelay: Delay before returning response.
    ///   - errorToThrow: Specific error to throw when failing.
    public init(response: String = "Mock tool response",
                toolCallsToSimulate: [ToolCallRecord] = [],
                shouldFail: Bool = false,
                shouldCallTools: Bool = false,
                simulatedDelay: TimeInterval = 0.1,
                errorToThrow: IntelligenceError? = nil) {
        self.response = response
        self.toolCallsToSimulate = toolCallsToSimulate
        self.shouldFail = shouldFail
        self.shouldCallTools = shouldCallTools
        self.simulatedDelay = simulatedDelay
        self.errorToThrow = errorToThrow
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        true
    }

    public func complete(prompt _: String,
                         configuration _: CompletionConfiguration) async throws -> IntelligenceResponse {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock failure")
        }

        return IntelligenceResponse(content: response,
                                    tokensUsed: response.count / 4,
                                    finishReason: .completed)
    }

    public func streamComplete(prompt _: String,
                               configuration _: CompletionConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: errorToThrow ?? IntelligenceError.requestFailed("Mock failure"))
                    return
                }

                continuation.yield(response)
                continuation.finish()
            }
        }
    }

    // MARK: - ToolProvider

    public func respondWithToolCalls(to prompt: String,
                                     tools: [any IntelligenceTool],
                                     configuration _: CompletionConfiguration) async throws
        -> (response: IntelligenceResponse,
            toolCalls: [ToolCallRecord]) {
        try await Task.sleep(for: .seconds(simulatedDelay))

        if shouldFail {
            throw errorToThrow ?? IntelligenceError.requestFailed("Mock tool failure")
        }

        var actualToolCalls = toolCallsToSimulate

        // Optionally call the actual tools
        if shouldCallTools {
            actualToolCalls = []
            for tool in tools {
                let startTime = Date()
                let output = try await tool.execute(arguments: ["prompt": prompt])
                let duration = Date().timeIntervalSince(startTime)

                actualToolCalls.append(ToolCallRecord(toolName: tool.name,
                                                      arguments: ["prompt": prompt],
                                                      output: output,
                                                      duration: duration))
            }
        }

        let intelligenceResponse = IntelligenceResponse(content: response,
                                                        tokensUsed: response.count / 4,
                                                        finishReason: .completed,
                                                        metadata: ["toolCalls": "\(actualToolCalls.count)"])

        return (intelligenceResponse, actualToolCalls)
    }
}

// MARK: - Mock Tool for Testing

/// A simple mock tool for testing tool provider implementations.
public struct MockTool: IntelligenceTool {
    public let name: String
    public let description: String
    public let responseToReturn: String
    public let shouldFail: Bool

    public init(name: String = "mockTool",
                description: String = "A mock tool for testing",
                responseToReturn: String = "Mock tool output",
                shouldFail: Bool = false) {
        self.name = name
        self.description = description
        self.responseToReturn = responseToReturn
        self.shouldFail = shouldFail
    }

    public func execute(arguments _: [String: Any]) async throws -> String {
        if shouldFail {
            throw IntelligenceError.requestFailed("Mock tool execution failed")
        }
        return responseToReturn
    }
}
