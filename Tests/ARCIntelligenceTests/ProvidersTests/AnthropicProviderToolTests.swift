//
//  AnthropicProviderToolTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Anthropic Provider Tool Tests")
struct AnthropicProviderToolTests {
    // MARK: - Helpers

    private func makeSUT(apiClient: MockAnthropicAPIClient = MockAnthropicAPIClient()) -> AnthropicProvider {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"),
                                            model: .sonnet,
                                            maxToolRounds: 5)
        return AnthropicProvider(configuration: config, apiClient: apiClient)
    }

    private struct TestTool: IntelligenceTool {
        let name: String
        let description: String
        let parametersSchema: ToolParametersSchema?
        let responseToReturn: String

        init(name: String = "test_tool",
             description: String = "A test tool",
             parametersSchema: ToolParametersSchema? = nil,
             responseToReturn: String = "tool output") {
            self.name = name
            self.description = description
            self.parametersSchema = parametersSchema
            self.responseToReturn = responseToReturn
        }

        func execute(arguments _: [String: Any]) async throws -> String {
            responseToReturn
        }
    }

    // MARK: - Schema Mapping

    @Test("Tool definition maps parameters schema correctly")
    func schemaMapping() {
        let sut = makeSUT()
        let parameters = [
            ToolParameter(name: "city",
                          type: .string,
                          description: "City name"),
            ToolParameter(name: "units",
                          type: .string,
                          description: "Temperature units",
                          enumValues: ["celsius", "fahrenheit"])
        ]
        let schema = ToolParametersSchema(parameters: parameters,
                                          required: ["city"])
        let tool = TestTool(parametersSchema: schema)

        let definition = sut.mapToolToDefinition(tool)

        #expect(definition.name == "test_tool")
        #expect(definition.description == "A test tool")
        #expect(definition.inputSchema.type == "object")
        #expect(definition.inputSchema.properties?["city"]?.type == "string")
        #expect(definition.inputSchema.properties?["units"]?.enumValues == ["celsius", "fahrenheit"])
        #expect(definition.inputSchema.required == ["city"])
    }

    @Test("Tool without schema maps to empty object schema")
    func emptySchema() {
        let sut = makeSUT()
        let tool = TestTool(parametersSchema: nil)

        let definition = sut.mapToolToDefinition(tool)

        #expect(definition.inputSchema.type == "object")
        #expect(definition.inputSchema.properties == nil)
    }

    // MARK: - Tool Execution

    @Test("Tool calling loop executes tool and returns final response")
    func toolCallingLoop() async throws {
        let mock = MockAnthropicAPIClient.withToolUse(toolName: "get_weather",
                                                      input: ["city": .string("Boston")],
                                                      followUpText: "The weather in Boston is 72°F.")
        let sut = makeSUT(apiClient: mock)

        let tool = TestTool(name: "get_weather",
                            description: "Get weather",
                            responseToReturn: "72°F, Sunny")

        let (response, toolCalls) = try await sut.respondWithToolCalls(to: "What's the weather in Boston?",
                                                                       tools: [tool],
                                                                       configuration: .default)

        #expect(response.content == "The weather in Boston is 72°F.")
        #expect(toolCalls.count == 1)
        #expect(toolCalls[0].toolName == "get_weather")
        #expect(toolCalls[0].output == "72°F, Sunny")
        #expect(toolCalls[0].duration > 0)
    }

    @Test("Tool call records include string arguments")
    func toolCallRecordArguments() async throws {
        let mock = MockAnthropicAPIClient.withToolUse(toolName: "search",
                                                      input: ["query": .string("restaurants")],
                                                      followUpText: "Found results.")
        let sut = makeSUT(apiClient: mock)

        let tool = TestTool(name: "search", responseToReturn: "results")

        let (_, toolCalls) = try await sut.respondWithToolCalls(to: "Search for restaurants",
                                                                tools: [tool],
                                                                configuration: .default)

        #expect(toolCalls[0].arguments["query"] == "restaurants")
    }

    @Test("Unknown tool produces error result")
    func unknownTool() async throws {
        let mock = MockAnthropicAPIClient.withToolUse(toolName: "unknown_tool",
                                                      input: [:],
                                                      followUpText: "I see the tool wasn't available.")
        let sut = makeSUT(apiClient: mock)

        let (response, toolCalls) = try await sut.respondWithToolCalls(to: "Test",
                                                                       tools: [],
                                                                       configuration: .default)

        #expect(response.content == "I see the tool wasn't available.")
        #expect(toolCalls[0].output.contains("Unknown tool"))
    }

    // MARK: - Multi-turn Tool Use

    @Test("Sends tool results back in message history")
    func toolResultsInHistory() async throws {
        let mock = MockAnthropicAPIClient.withToolUse(toolName: "calc",
                                                      input: ["expr": .string("2+2")],
                                                      followUpText: "The result is 4.")
        let sut = makeSUT(apiClient: mock)

        let tool = TestTool(name: "calc", responseToReturn: "4")

        _ = try await sut.respondWithToolCalls(to: "Calculate 2+2",
                                               tools: [tool],
                                               configuration: .default)

        // Second request should contain the tool result
        #expect(mock.sendMessageCallCount == 2)
        let secondRequest = mock.allRequests[1]
        #expect(secondRequest.messages.count == 3) // user, assistant(tool_use), user(tool_result)
    }

    // MARK: - Error Handling

    @Test("API errors propagate through tool calling")
    func apiErrorsPropagateInToolCalling() async {
        let mock = MockAnthropicAPIClient.withError(.rateLimitExceeded)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.respondWithToolCalls(to: "Test",
                                                   tools: [],
                                                   configuration: .default)
        }
    }
}
