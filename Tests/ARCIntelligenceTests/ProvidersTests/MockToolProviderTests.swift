//
//  MockToolProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Testing
@testable import ARCIntelligence
@testable import ARCIntelligenceMocks

@Suite("Mock Tool Provider Tests", .tags(.unit))
struct MockToolProviderTests {
    // MARK: - Availability Tests

    @Test("Mock tool provider is always available")
    func isAvailable() async {
        let provider = MockToolProvider()
        let available = await provider.isAvailable()
        #expect(available)
    }

    // MARK: - Response Tests

    @Test("Respond returns configured response")
    func respondReturnsConfiguredResponse() async throws {
        let expectedResponse = "The answer is 42"
        let provider = MockToolProvider(response: expectedResponse)

        let response = try await provider.respond(to: "What is the answer?",
                                                  tools: [],
                                                  configuration: .default)

        #expect(response.content == expectedResponse)
    }

    @Test("Respond with tool calls returns simulated calls")
    func respondWithToolCallsReturnsSimulatedCalls() async throws {
        let simulatedCalls = [ToolCallRecord(toolName: "calculator",
                                             arguments: ["expression": "2+2"],
                                             output: "4",
                                             duration: 0.1)]
        let provider = MockToolProvider(response: "The result is 4",
                                        toolCallsToSimulate: simulatedCalls)

        let (response, toolCalls) = try await provider.respondWithToolCalls(to: "Calculate 2+2",
                                                                            tools: [],
                                                                            configuration: .default)

        #expect(response.content == "The result is 4")
        #expect(toolCalls.count == 1)
        #expect(toolCalls[0].toolName == "calculator")
        #expect(toolCalls[0].output == "4")
    }

    // MARK: - Tool Execution Tests

    @Test("Provider calls actual tools when shouldCallTools is true")
    func providerCallsActualTools() async throws {
        let tool = MockTool(name: "greeter",
                            description: "Greets people",
                            responseToReturn: "Hello, World!")
        let provider = MockToolProvider(response: "Greeting sent",
                                        shouldCallTools: true)

        let (_, toolCalls) = try await provider.respondWithToolCalls(to: "Say hello",
                                                                     tools: [tool],
                                                                     configuration: .default)

        #expect(toolCalls.count == 1)
        #expect(toolCalls[0].toolName == "greeter")
        #expect(toolCalls[0].output == "Hello, World!")
    }

    @Test("MockTool returns configured response")
    func mockToolReturnsConfiguredResponse() async throws {
        let tool = MockTool(name: "echo",
                            description: "Echoes input",
                            responseToReturn: "Echo response")

        let result = try await tool.execute(arguments: [:])

        #expect(result == "Echo response")
    }

    @Test("MockTool throws error when configured to fail")
    func mockToolThrowsErrorWhenFailing() async {
        let tool = MockTool(name: "failing",
                            description: "Always fails",
                            shouldFail: true)

        await #expect(throws: IntelligenceError.self) {
            _ = try await tool.execute(arguments: [:])
        }
    }

    // MARK: - Error Tests

    @Test("Provider throws error when shouldFail is true")
    func providerThrowsErrorWhenFailing() async {
        let provider = MockToolProvider(shouldFail: true)

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.respond(to: "Test",
                                           tools: [],
                                           configuration: .default)
        }
    }

    @Test("Provider throws configured error")
    func providerThrowsConfiguredError() async {
        let expectedError = IntelligenceError.rateLimitExceeded
        let provider = MockToolProvider(shouldFail: true,
                                        errorToThrow: expectedError)

        await #expect(throws: IntelligenceError.self) {
            _ = try await provider.respond(to: "Test",
                                           tools: [],
                                           configuration: CompletionConfiguration.default)
        }
    }

    // MARK: - Metadata Tests

    @Test("Response includes tool call count in metadata")
    func responseIncludesToolCallMetadata() async throws {
        let simulatedCalls = [
            ToolCallRecord(toolName: "tool1", arguments: [:], output: "out1", duration: 0.1),
            ToolCallRecord(toolName: "tool2", arguments: [:], output: "out2", duration: 0.1)
        ]
        let provider = MockToolProvider(response: "Done",
                                        toolCallsToSimulate: simulatedCalls)

        let (response, _) = try await provider.respondWithToolCalls(to: "Test",
                                                                    tools: [],
                                                                    configuration: .default)

        #expect(response.metadata["toolCalls"] == "2")
    }

    // MARK: - Stream Tests

    @Test("Stream complete returns response")
    func streamCompleteReturnsResponse() async throws {
        let expectedResponse = "Streamed response"
        let provider = MockToolProvider(response: expectedResponse)

        var streamedContent = ""
        for try await chunk in provider.streamComplete(prompt: "Test",
                                                       configuration: .default) {
            streamedContent += chunk
        }

        #expect(streamedContent == expectedResponse)
    }
}
