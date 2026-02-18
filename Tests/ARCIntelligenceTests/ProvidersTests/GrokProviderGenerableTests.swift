//
//  GrokProviderGenerableTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Grok Provider Generable Tests")
struct GrokProviderGenerableTests {
    // MARK: - Test Types

    struct MovieReview: Codable, Sendable, Equatable {
        let title: String
        let rating: Int
        let summary: String
    }

    // MARK: - Helpers

    private func makeSUT(apiClient: MockOpenAICompatibleAPIClient = MockOpenAICompatibleAPIClient()) -> GrokProvider {
        let config = GrokConfiguration(authentication: .apiKey("test-key"),
                                       model: .grok3Fast)
        return GrokProvider(configuration: config, apiClient: apiClient)
    }

    private func mockWithToolCallJsonOutput(_ json: String) -> MockOpenAICompatibleAPIClient {
        let mock = MockOpenAICompatibleAPIClient()
        let argumentsJson = "{\"json_output\":\(json.debugDescription)}"
        let toolCall = OpenAIToolCall(id: "call_gen",
                                      type: "function",
                                      function: OpenAIFunctionCall(name: "generate_moviereview",
                                                                   arguments: argumentsJson))
        let message = OpenAIChatChoiceMessage(role: "assistant",
                                              content: nil,
                                              toolCalls: [toolCall])
        mock.chatResponses = [
            OpenAIChatResponse(id: "chatcmpl-gen",
                               object: "chat.completion",
                               model: "grok-3-fast",
                               choices: [
                                   OpenAIChatChoice(index: 0,
                                                    message: message,
                                                    finishReason: "tool_calls")
                               ],
                               usage: OpenAIUsage(promptTokens: 50,
                                                  completionTokens: 100,
                                                  totalTokens: 150))
        ]
        return mock
    }

    // MARK: - Forced Tool Use

    @Test("Generate sends forced tool_choice with correct tool name")
    func forcedToolChoice() async throws {
        let mock = mockWithToolCallJsonOutput("""
        {"title":"Inception","rating":9,"summary":"A masterpiece"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review Inception",
                                   configuration: .default)

        let request = mock.lastRequest
        #expect(request?.toolChoice == .function(name: "generate_moviereview"))
        #expect(request?.tools?.count == 1)
        #expect(request?.tools?.first?.function.name == "generate_moviereview")
    }

    // MARK: - JSON Decoding

    @Test("Generate decodes JSON from tool call output")
    func decodesJson() async throws {
        let mock = mockWithToolCallJsonOutput("""
        {"title":"Inception","rating":9,"summary":"Mind-bending sci-fi"}
        """)
        let sut = makeSUT(apiClient: mock)

        let result: MovieReview = try await sut.generate(MovieReview.self,
                                                         prompt: "Review Inception",
                                                         configuration: .default)

        #expect(result.title == "Inception")
        #expect(result.rating == 9)
        #expect(result.summary == "Mind-bending sci-fi")
    }

    // MARK: - Schema Description

    @Test("Generate with schema description includes it in tool definition")
    func schemaDescription() async throws {
        let mock = mockWithToolCallJsonOutput("""
        {"title":"Test","rating":5,"summary":"ok"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review a movie",
                                   schemaDescription: "A structured movie review with title, rating, and summary",
                                   configuration: .default)

        let toolDescription = mock.lastRequest?.tools?.first?.function.description
        #expect(toolDescription == "A structured movie review with title, rating, and summary")
    }

    // MARK: - Parse Errors

    @Test("Generate throws parse error on invalid JSON")
    func invalidJson() async {
        let mock = mockWithToolCallJsonOutput("not valid json")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }

    @Test("Generate throws parse error when no tool call returned")
    func missingToolCall() async {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "Just text, no tool call")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }
}
