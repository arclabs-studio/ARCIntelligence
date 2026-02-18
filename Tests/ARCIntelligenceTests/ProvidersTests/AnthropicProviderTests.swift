//
//  AnthropicProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Anthropic Provider Tests", .tags(.unit))
struct AnthropicProviderTests {
    // MARK: - Helpers

    private func makeSUT(apiClient: MockAnthropicAPIClient = MockAnthropicAPIClient(),
                         model: AnthropicModel = .sonnet) -> AnthropicProvider {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"),
                                            model: model)
        return AnthropicProvider(configuration: config, apiClient: apiClient)
    }

    // MARK: - Identification

    @Test("Provider has correct id")
    func providerId() {
        let sut = makeSUT()
        #expect(sut.id == "com.arclabs.intelligence.anthropic")
    }

    @Test("Provider has correct display name")
    func providerDisplayName() {
        let sut = makeSUT()
        #expect(sut.displayName == "Anthropic Claude")
    }

    @Test("Provider has correct version")
    func providerVersion() {
        let sut = makeSUT()
        #expect(sut.version == "1.0")
    }

    // MARK: - Availability

    @Test("Provider is available with valid API key")
    func isAvailableWithKey() async {
        let sut = makeSUT()
        let available = await sut.isAvailable()
        #expect(available)
    }

    @Test("Provider is not available with empty API key")
    func isNotAvailableWithEmptyKey() async {
        let config = AnthropicConfiguration(authentication: .apiKey(""))
        let sut = AnthropicProvider(configuration: config,
                                    apiClient: MockAnthropicAPIClient())
        let available = await sut.isAvailable()
        #expect(!available)
    }

    // MARK: - Complete

    @Test("Complete returns mapped response")
    func completeReturnsResponse() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "Hello from Claude")
        let sut = makeSUT(apiClient: mock)

        let response = try await sut.complete(prompt: "Say hello",
                                              configuration: .default)

        #expect(response.content == "Hello from Claude")
        #expect(response.tokensUsed == 30)
        #expect(response.finishReason == .completed)
        #expect(response.metadata["model"] == "claude-sonnet-4-5-20250929")
    }

    @Test("Complete forwards configuration to request")
    func completeForwardsConfig() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "ok")
        let sut = makeSUT(apiClient: mock, model: .opus)

        _ = try await sut.complete(prompt: "Test",
                                   configuration: CompletionConfiguration(temperature: 0.5,
                                                                          maxTokens: 1000,
                                                                          systemPrompt: "Be helpful"))

        let request = mock.lastRequest
        #expect(request?.model == "claude-opus-4-6")
        #expect(request?.temperature == 0.5)
        #expect(request?.maxTokens == 1000)
        #expect(request?.system == "Be helpful")
        #expect(request?.stream == false)
    }

    @Test("Complete propagates errors")
    func completePropagatesErrors() async {
        let mock = MockAnthropicAPIClient.withError(.authenticationFailed)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.complete(prompt: "Test", configuration: .default)
        }
    }

    // MARK: - Stream Complete

    @Test("Stream complete yields text deltas")
    func streamCompleteYieldsDeltas() async throws {
        let mock = MockAnthropicAPIClient()
        mock.streamEvents = [
            .contentBlockDelta(index: 0, text: "Hello "),
            .contentBlockDelta(index: 0, text: "world"),
            .messageStop
        ]
        let sut = makeSUT(apiClient: mock)

        var collected = ""
        for try await chunk in sut.streamComplete(prompt: "Test", configuration: .default) {
            collected += chunk
        }

        #expect(collected == "Hello world")
    }

    @Test("Stream complete propagates errors")
    func streamCompletePropagatesErrors() async {
        let mock = MockAnthropicAPIClient.withError(.rateLimitExceeded)
        let sut = makeSUT(apiClient: mock)

        await #expect(throws: IntelligenceError.self) {
            for try await _ in sut.streamComplete(prompt: "Test", configuration: .default) {}
        }
    }

    // MARK: - Conversation

    @Test("Send message returns assistant message")
    func sendMessageReturnsAssistantMessage() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "I can help with that!")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(systemPrompt: "Be helpful")
        let userMessage = Message(role: .user, content: "Help me")

        let response = try await sut.sendMessage(userMessage, in: conversation)

        #expect(response.role == .assistant)
        #expect(response.content == "I can help with that!")
    }

    @Test("Continue conversation sends user message")
    func continueConversation() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "Response text")
        let sut = makeSUT(apiClient: mock)

        let conversation = Conversation(messages: [
            Message(role: .user, content: "First message"),
            Message(role: .assistant, content: "First reply")
        ])

        let response = try await sut.continueConversation(conversation, with: "Follow up")

        #expect(response.role == .assistant)
        #expect(response.content == "Response text")

        // Verify all messages were sent
        let request = mock.lastRequest
        #expect(request?.messages.count == 3) // 2 history + 1 new
    }

    @Test("Estimate tokens returns reasonable estimate")
    func estimateTokens() {
        let sut = makeSUT()

        let conversation = Conversation(systemPrompt: "System prompt",
                                        messages: [Message(role: .user, content: "Hello there")])

        let estimate = sut.estimateTokens(for: conversation)
        #expect(estimate > 0)
    }

    // MARK: - Stop Reason Mapping

    @Test("Stop reason end_turn maps to completed")
    func stopReasonEndTurn() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "ok", stopReason: "end_turn")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .completed)
    }

    @Test("Stop reason max_tokens maps to maxTokens")
    func stopReasonMaxTokens() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "ok", stopReason: "max_tokens")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .maxTokens)
    }

    @Test("Stop reason stop_sequence maps to stopSequence")
    func stopReasonStopSequence() async throws {
        let mock = MockAnthropicAPIClient.withResponse(content: "ok", stopReason: "stop_sequence")
        let sut = makeSUT(apiClient: mock)
        let response = try await sut.complete(prompt: "test", configuration: .default)
        #expect(response.finishReason == .stopSequence)
    }
}
