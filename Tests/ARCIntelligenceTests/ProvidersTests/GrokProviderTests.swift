//
//  GrokProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Grok Provider Tests", .tags(.unit)) struct GrokProviderTests {
    // MARK: - Helpers

    private func makeSUT(apiClient: MockOpenAICompatibleAPIClient = MockOpenAICompatibleAPIClient(),
                         model: GrokModel = .grok3Fast) -> GrokProvider {
        let config = GrokConfiguration(authentication: .apiKey("test-key"),
                                       model: model)
        return GrokProvider(configuration: config, apiClient: apiClient)
    }

    // MARK: - Identification

    @Test("Provider has correct id") func providerId() {
        let sut = makeSUT()
        #expect(sut.id == "com.arclabs.intelligence.grok")
    }

    @Test("Provider has correct display name") func providerDisplayName() {
        let sut = makeSUT()
        #expect(sut.displayName == "Grok (xAI)")
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
        let config = GrokConfiguration(authentication: .apiKey(""))
        let sut = GrokProvider(configuration: config,
                               apiClient: MockOpenAICompatibleAPIClient())
        let available = await sut.isAvailable()
        #expect(!available)
    }

    // MARK: - Complete

    @Test("Complete returns mapped response") func completeReturnsResponse() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "Hello from Grok")
        let sut = makeSUT(apiClient: mock)

        let response = try await sut.complete(prompt: "Say hello",
                                              configuration: .default)

        #expect(response.content == "Hello from Grok")
        #expect(response.tokensUsed == 30)
        #expect(response.finishReason == .completed)
    }

    @Test("Complete forwards configuration to request") func completeForwardsConfig() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "ok")
        let sut = makeSUT(apiClient: mock, model: .grok3)

        _ = try await sut.complete(prompt: "Test",
                                   configuration: CompletionConfiguration(temperature: 0.5,
                                                                          maxTokens: 1000,
                                                                          systemPrompt: "Be helpful"))

        let request = mock.lastRequest
        #expect(request?.model == "grok-3")
        #expect(request?.temperature == 0.5)
        #expect(request?.maxTokens == 1000)
        #expect(request?.stream == false)
    }

    @Test("Complete propagates errors") func completePropagatesErrors() async {
        let mock = MockOpenAICompatibleAPIClient.withError(.authenticationFailed)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.complete(prompt: "Test", configuration: .default)
        }
    }

    // MARK: - Stream Complete

    @Test("Stream complete yields text deltas") func streamCompleteYieldsDeltas() async throws {
        let mock = MockOpenAICompatibleAPIClient()
        mock.streamChunks = [OpenAIStreamChunk(id: "c1",
                                               choices: [OpenAIStreamChoice(index: 0,
                                                                            delta: OpenAIStreamDelta(role: nil,
                                                                                                     content: "Hello ",
                                                                                                     toolCalls: nil),
                                                                            finishReason: nil)],
                                               usage: nil),
                             OpenAIStreamChunk(id: "c2",
                                               choices: [OpenAIStreamChoice(index: 0,
                                                                            delta: OpenAIStreamDelta(role: nil,
                                                                                                     content: "world",
                                                                                                     toolCalls: nil),
                                                                            finishReason: nil)],
                                               usage: nil),
                             OpenAIStreamChunk(id: "c3",
                                               choices: [OpenAIStreamChoice(index: 0,
                                                                            delta: OpenAIStreamDelta(role: nil,
                                                                                                     content: nil,
                                                                                                     toolCalls: nil),
                                                                            finishReason: "stop")],
                                               usage: nil)]
        let sut = makeSUT(apiClient: mock)

        var collected = ""
        for try await chunk in sut.streamComplete(prompt: "Test", configuration: .default) {
            collected += chunk
        }

        #expect(collected == "Hello world")
    }

    @Test("Stream complete propagates errors") func streamCompletePropagatesErrors() async {
        let mock = MockOpenAICompatibleAPIClient.withError(.rateLimitExceeded)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            for try await _ in sut.streamComplete(prompt: "Test", configuration: .default) {}
        }
    }

    // MARK: - Conversation

    @Test("Send message returns assistant message") func sendMessageReturnsAssistantMessage() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "I can help with that!")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(systemPrompt: "Be helpful")
        let userMessage = Message(role: .user, content: "Help me")

        let response = try await sut.sendMessage(userMessage, in: conversation)

        #expect(response.role == .assistant)
        #expect(response.content == "I can help with that!")
    }

    @Test("Continue conversation sends user message") func continueConversation() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "Response text")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(messages: [Message(role: .user, content: "First message"),
                                                   Message(role: .assistant, content: "First reply")])

        let response = try await sut.continueConversation(conversation, with: "Follow up")

        #expect(response.role == .assistant)
        #expect(response.content == "Response text")

        let request = mock.lastRequest
        #expect(request?.messages.count == 3)
    }

    @Test("Estimate tokens returns reasonable estimate") func estimateTokens() {
        let sut = makeSUT()

        let conversation = Conversation(systemPrompt: "System prompt",
                                        messages: [Message(role: .user, content: "Hello there")])

        let estimate = sut.estimateTokens(for: conversation)
        #expect(estimate > 0)
    }

    // MARK: - Stop Reason Mapping

    @Test("Stop reason 'stop' maps to completed") func stopReasonStop() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "ok", finishReason: "stop")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .completed)
    }

    @Test("Stop reason 'length' maps to maxTokens") func stopReasonLength() async throws {
        let mock = MockOpenAICompatibleAPIClient.withResponse(content: "ok", finishReason: "length")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .maxTokens)
    }
}
