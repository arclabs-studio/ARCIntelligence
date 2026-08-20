//
//  GeminiProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Testing
@testable import ARCIntelligence

@Suite(.tags(.unit)) struct GeminiProviderTests {
    // MARK: - Helpers

    private func makeSUT(apiClient: MockGeminiAPIClient = MockGeminiAPIClient(),
                         model: GeminiModel = .gemini2Flash) -> GeminiProvider {
        let config = GeminiConfiguration(authentication: .apiKey("test-key"),
                                         model: model)
        return GeminiProvider(configuration: config, apiClient: apiClient)
    }

    // MARK: - Identification

    @Test("Provider has correct id") func providerId() {
        let sut = makeSUT()
        #expect(sut.id == "com.arclabs.intelligence.gemini")
    }

    @Test("Provider has correct display name") func providerDisplayName() {
        let sut = makeSUT()
        #expect(sut.displayName == "Google Gemini")
    }

    @Test("Provider has correct version") func providerVersion() {
        let sut = makeSUT()
        #expect(sut.version == "1.0")
    }

    // MARK: - Availability

    @Test("Provider is available with valid API key") func isAvailableWithKey() async {
        let sut = makeSUT()
        let available = await sut.isAvailable()
        #expect(available)
    }

    @Test("Provider is not available with empty API key") func isNotAvailableWithEmptyKey() async {
        let config = GeminiConfiguration(authentication: .apiKey(""))
        let sut = GeminiProvider(configuration: config,
                                 apiClient: MockGeminiAPIClient())
        let available = await sut.isAvailable()
        #expect(!available)
    }

    // MARK: - Complete

    @Test("Complete returns mapped response") func completeReturnsResponse() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "Hello from Gemini")
        let sut = makeSUT(apiClient: mock)

        let response = try await sut.complete(prompt: "Say hello",
                                              configuration: .default)

        #expect(response.content == "Hello from Gemini")
        #expect(response.tokensUsed == 30)
        #expect(response.finishReason == .completed)
    }

    @Test("Complete forwards configuration to request") func completeForwardsConfig() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "ok")
        let sut = makeSUT(apiClient: mock, model: .gemini15Pro)

        _ = try await sut.complete(prompt: "Test",
                                   configuration: CompletionConfiguration(temperature: 0.5,
                                                                          maxTokens: 1000,
                                                                          systemPrompt: "Be helpful"))

        let request = mock.lastRequest
        #expect(request?.model == "gemini-1.5-pro")
        #expect(request?.generationConfig?.temperature == 0.5)
        #expect(request?.generationConfig?.maxOutputTokens == 1000)
        let systemText = request?.systemInstruction?.parts.compactMap {
            if case let .text(text) = $0 {
                return text
            }
            return nil
        }.first
        #expect(systemText == "Be helpful")
    }

    @Test("Complete propagates errors") func completePropagatesErrors() async {
        let mock = MockGeminiAPIClient.withError(.authenticationFailed)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.complete(prompt: "Test", configuration: .default)
        }
    }

    // MARK: - Stream Complete

    @Test("Stream complete yields text deltas") func streamCompleteYieldsDeltas() async throws {
        let mock = MockGeminiAPIClient()
        let helloContent = GeminiContent(role: "model", parts: [.text("Hello ")])
        let worldContent = GeminiContent(role: "model", parts: [.text("world")])
        mock.streamChunks = [GeminiGenerateContentResponse(candidates: [GeminiCandidate(content: helloContent,
                                                                                        finishReason: nil)],
                                                           usageMetadata: nil,
                                                           modelVersion: nil),
                             GeminiGenerateContentResponse(candidates: [GeminiCandidate(content: worldContent,
                                                                                        finishReason: "STOP")],
                                                           usageMetadata: nil,
                                                           modelVersion: nil)]
        let sut = makeSUT(apiClient: mock)

        var collected = ""
        for try await chunk in sut.streamComplete(prompt: "Test", configuration: .default) {
            collected += chunk
        }

        #expect(collected == "Hello world")
    }

    @Test("Stream complete propagates errors") func streamCompletePropagatesErrors() async {
        let mock = MockGeminiAPIClient.withError(.rateLimitExceeded)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            for try await _ in sut.streamComplete(prompt: "Test", configuration: .default) {}
        }
    }

    // MARK: - Conversation

    @Test("Send message returns assistant message") func sendMessageReturnsAssistantMessage() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "I can help with that!")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(systemPrompt: "Be helpful")
        let userMessage = Message(role: .user, content: "Help me")

        let response = try await sut.sendMessage(userMessage, in: conversation)

        #expect(response.role == .assistant)
        #expect(response.content == "I can help with that!")
    }

    @Test("Continue conversation sends user message") func continueConversation() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "Response text")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(messages: [Message(role: .user, content: "First message"),
                                                   Message(role: .assistant, content: "First reply")])

        let response = try await sut.continueConversation(conversation, with: "Follow up")

        #expect(response.role == .assistant)
        #expect(response.content == "Response text")

        // Verify all 3 contents were sent (2 history + 1 new)
        let request = mock.lastRequest
        #expect(request?.contents.count == 3)
    }

    @Test("Estimate tokens returns reasonable estimate") func estimateTokens() {
        let sut = makeSUT()

        let conversation = Conversation(systemPrompt: "System prompt",
                                        messages: [Message(role: .user, content: "Hello there")])

        let estimate = sut.estimateTokens(for: conversation)
        #expect(estimate > 0)
    }

    // MARK: - Finish Reason Mapping

    @Test("STOP finish reason maps to completed") func finishReasonStop() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "ok", finishReason: "STOP")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .completed)
    }

    @Test("MAX_TOKENS finish reason maps to maxTokens") func finishReasonMaxTokens() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "ok", finishReason: "MAX_TOKENS")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .maxTokens)
    }

    @Test("SAFETY finish reason maps to contentFilter") func finishReasonSafety() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "", finishReason: "SAFETY")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .contentFilter)
    }

    // MARK: - API Endpoint

    @Test("Request uses correct model ID in path") func requestUsesModelId() async throws {
        let mock = MockGeminiAPIClient.withResponse(text: "ok")
        let sut = makeSUT(apiClient: mock, model: .gemini2FlashLite)

        _ = try await sut.complete(prompt: "test", configuration: .default)

        #expect(mock.lastRequest?.model == "gemini-2.0-flash-lite")
    }
}
