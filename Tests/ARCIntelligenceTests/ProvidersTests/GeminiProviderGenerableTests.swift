//
//  GeminiProviderGenerableTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Testing
@testable import ARCIntelligence

@Suite(.tags(.unit)) struct GeminiProviderGenerableTests {
    // MARK: - Test Types

    struct MovieReview: Codable, Equatable {
        let title: String
        let rating: Int
        let summary: String
    }

    // MARK: - Helpers

    private func makeSUT(apiClient: MockGeminiAPIClient = MockGeminiAPIClient()) -> GeminiProvider {
        let config = GeminiConfiguration(authentication: .apiKey("test-key"),
                                         model: .gemini2Flash)
        return GeminiProvider(configuration: config, apiClient: apiClient)
    }

    private func mockWithFunctionCallJsonOutput(_ json: String,
                                                functionName: String = "generate_moviereview")
    -> MockGeminiAPIClient {
        let mock = MockGeminiAPIClient()
        let functionCall = GeminiFunctionCall(name: functionName, id: "call_gen", args: ["json_output": .string(json)])
        let modelContent = GeminiContent(role: "model", parts: [.functionCall(functionCall)])
        let candidate = GeminiCandidate(content: modelContent, finishReason: "STOP")
        let usage = GeminiUsageMetadata(promptTokenCount: 50, candidatesTokenCount: 100, totalTokenCount: 150)
        mock.responses = [GeminiGenerateContentResponse(candidates: [candidate],
                                                        usageMetadata: usage,
                                                        modelVersion: "gemini-2.0-flash")]
        return mock
    }

    // MARK: - Forced Function Call

    @Test("Generate sends toolConfig with mode ANY and correct function name") func forcedToolConfig() async throws {
        let mock = mockWithFunctionCallJsonOutput("""
        {"title":"Inception","rating":9,"summary":"A masterpiece"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review Inception",
                                   configuration: .default)

        let request = mock.lastRequest
        #expect(request?.toolConfig?.functionCallingConfig.mode == "ANY")
        #expect(request?.toolConfig?.functionCallingConfig.allowedFunctionNames == ["generate_moviereview"])
        #expect(request?.tools?.first?.functionDeclarations?.count == 1)
        #expect(request?.tools?.first?.functionDeclarations?.first?.name == "generate_moviereview")
    }

    // MARK: - JSON Decoding

    @Test("Generate decodes JSON from function call output") func decodesJson() async throws {
        let mock = mockWithFunctionCallJsonOutput("""
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

    @Test("Generate with schema description includes it in function declaration") func schemaDescription() async throws {
        let mock = mockWithFunctionCallJsonOutput("""
        {"title":"Test","rating":5,"summary":"ok"}
        """)
        let sut = makeSUT(apiClient: mock)

        _ = try await sut.generate(MovieReview.self,
                                   prompt: "Review a movie",
                                   schemaDescription: "A structured movie review with title, rating, and summary",
                                   configuration: .default)

        let funcDescription = mock.lastRequest?.tools?.first?.functionDeclarations?.first?.description
        #expect(funcDescription == "A structured movie review with title, rating, and summary")
    }

    // MARK: - Parse Errors

    @Test("Generate throws parse error on invalid JSON") func invalidJson() async {
        let mock = mockWithFunctionCallJsonOutput("not valid json")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }

    @Test("Generate throws parse error when no function call returned") func missingFunctionCall() async {
        let mock = MockGeminiAPIClient.withResponse(text: "Just text, no function call")
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.generate(MovieReview.self,
                                       prompt: "Review a movie",
                                       configuration: .default)
        }
    }
}
