//
//  OpenAIProviderToolTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("OpenAI Provider Tool Tests")
struct OpenAIProviderToolTests {
    // MARK: - Helpers

    private func makeSUT(apiClient: MockOpenAICompatibleAPIClient = MockOpenAICompatibleAPIClient()) -> OpenAIProvider {
        let config = OpenAIConfiguration(authentication: .apiKey("test-key"),
                                         model: .gpt4oMini,
                                         maxToolRounds: 5)
        return OpenAIProvider(configuration: config, apiClient: apiClient)
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

        #expect(definition.function.name == "test_tool")
        #expect(definition.function.description == "A test tool")
        #expect(definition.type == "function")
        #expect(definition.function.parameters.type == "object")
        #expect(definition.function.parameters.properties?["city"]?.type == "string")
        #expect(definition.function.parameters.properties?["units"]?.enumValues == ["celsius", "fahrenheit"])
        #expect(definition.function.parameters.required == ["city"])
    }

    @Test("Tool without schema maps to empty object schema")
    func emptySchema() {
        let sut = makeSUT()
        let tool = TestTool(parametersSchema: nil)

        let definition = sut.mapToolToDefinition(tool)

        #expect(definition.function.parameters.type == "object")
        #expect(definition.function.parameters.properties == nil)
    }

    // MARK: - Tool Execution

    @Test("Tool calling loop executes tool and returns final response")
    func toolCallingLoop() async throws {
        let mock = MockOpenAICompatibleAPIClient.withToolCall(
            functionName: "get_weather",
            arguments: "{\"city\":\"Boston\"}",
            followUpText: "The weather in Boston is 72°F."
        )
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
        let mock = MockOpenAICompatibleAPIClient.withToolCall(
            functionName: "search",
            arguments: "{\"query\":\"restaurants\"}",
            followUpText: "Found results."
        )
        let sut = makeSUT(apiClient: mock)

        let tool = TestTool(name: "search", responseToReturn: "results")

        let (_, toolCalls) = try await sut.respondWithToolCalls(to: "Search for restaurants",
                                                                tools: [tool],
                                                                configuration: .default)

        #expect(toolCalls[0].arguments["query"] == "restaurants")
    }

    @Test("Unknown tool produces error result")
    func unknownTool() async throws {
        let mock = MockOpenAICompatibleAPIClient.withToolCall(
            functionName: "unknown_tool",
            arguments: "{}",
            followUpText: "I see the tool wasn't available."
        )
        let sut = makeSUT(apiClient: mock)

        let (response, toolCalls) = try await sut.respondWithToolCalls(to: "Test",
                                                                       tools: [],
                                                                       configuration: .default)

        #expect(response.content == "I see the tool wasn't available.")
        #expect(toolCalls[0].output.contains("Unknown tool"))
    }

    // MARK: - Multi-turn Tool Use

    @Test("Sends tool results as role:tool messages in history")
    func toolResultsInHistory() async throws {
        let mock = MockOpenAICompatibleAPIClient.withToolCall(
            functionName: "calc",
            arguments: "{\"expr\":\"2+2\"}",
            followUpText: "The result is 4."
        )
        let sut = makeSUT(apiClient: mock)

        let tool = TestTool(name: "calc", responseToReturn: "4")

        _ = try await sut.respondWithToolCalls(to: "Calculate 2+2",
                                               tools: [tool],
                                               configuration: .default)

        // Second request should contain the tool result message
        #expect(mock.sendCallCount == 2)
        let secondRequest = mock.allRequests[1]

        // Messages: user, assistant(tool_calls), tool(result)
        let toolMessage = secondRequest.messages.last
        #expect(toolMessage?.role == "tool")
        #expect(toolMessage?.toolCallId != nil)
        #expect(toolMessage?.content == "4")
    }

    // MARK: - Error Handling

    @Test("API errors propagate through tool calling")
    func apiErrorsPropagateInToolCalling() async {
        let mock = MockOpenAICompatibleAPIClient.withError(.rateLimitExceeded)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.respondWithToolCalls(to: "Test",
                                                   tools: [],
                                                   configuration: .default)
        }
    }
}
