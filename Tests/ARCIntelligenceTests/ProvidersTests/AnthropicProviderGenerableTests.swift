//
//  AnthropicProviderGenerableTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Anthropic Provider Generable Tests", .tags(.unit)) struct AnthropicProviderGenerableTests {
    // MARK: - Test Types

    struct MovieReview: Codable, Sendable, Equatable {
        let title: String
        let rating: Int
        let summary: String
    }

    // MARK: - Helpers

    private func makeSUT(apiClient: MockAnthropicAPIClient = MockAnthropicAPIClient()) -> AnthropicProvider {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"),
                                            model: .sonnet)
        return AnthropicProvider(configuration: config, apiClient: apiClient)
    }

    private func mockWithToolUseJsonOutput(_ json: String) -> MockAnthropicAPIClient {
        let mock = MockAnthropicAPIClient()
        mock.messageResponses = [AnthropicMessageResponse(id: "msg_test",
                                                          type: "message",
                                                          model: "claude-sonnet-4-5-20250929",
                                                          content: [.toolUse(id: "toolu_gen",
                                                                             name: "generate_moviereview",
                                                                             input: ["json_output": .string(json)])],
                                                          stopReason: "tool_use",
                                                          usage: AnthropicUsage(inputTokens: 50, outputTokens: 100))]
        return mock
    }

    // MARK: - Forced Tool Use

    @Test("Generate sends forced tool_choice with correct tool name") func forcedToolChoice() async throws {
        let mock = mockWithToolUseJsonOutput("""
        {"title":"Inception","rating":9,"summary":"A masterpiece"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review Inception",
                                   configuration: .default)

        let request = mock.lastRequest
        #expect(request?.toolChoice == .tool(name: "generate_moviereview"))
        #expect(request?.tools?.count == 1)
        #expect(request?.tools?.first?.name == "generate_moviereview")
    }

    // MARK: - JSON Decoding

    @Test("Generate decodes JSON from tool_use output") func decodesJson() async throws {
        let mock = mockWithToolUseJsonOutput("""
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

    @Test("Generate with schema description includes it in tool definition") func schemaDescription() async throws {
        let mock = mockWithToolUseJsonOutput("""
        {"title":"Test","rating":5,"summary":"ok"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review a movie",
                                   schemaDescription: "A structured movie review with title, rating, and summary",
                                   configuration: .default)

        let toolDescription = mock.lastRequest?.tools?.first?.description
        #expect(toolDescription == "A structured movie review with title, rating, and summary")
    }

    // MARK: - Parse Errors

    @Test("Generate throws parse error on invalid JSON") func invalidJson() async {
        let mock = mockWithToolUseJsonOutput("not valid json")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }

    @Test("Generate throws parse error when no tool_use block returned") func missingToolUse() async {
        let mock = MockAnthropicAPIClient.withResponse(content: "Just text, no tool use")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }
}
