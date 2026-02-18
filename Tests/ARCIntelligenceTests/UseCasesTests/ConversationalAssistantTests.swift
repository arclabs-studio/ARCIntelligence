//
//  ConversationalAssistantTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Testing
@testable import ARCIntelligence
@testable import ARCIntelligenceMocks

@Suite("Conversational Assistant Tests", .tags(.unit))
struct ConversationalAssistantTests {
    @Test("Start conversation creates new conversation")
    func startConversationCreatesNew() async {
        let provider = MockIntelligenceProvider()
        let assistant = ConversationalAssistant(provider: provider)

        let conversation = await assistant.startConversation()
        #expect(conversation.messages.isEmpty)
    }

    @Test("Start conversation with system prompt")
    func startConversationWithSystemPrompt() async {
        let provider = MockIntelligenceProvider()
        let assistant = ConversationalAssistant(provider: provider)
        let systemPrompt = "You are helpful"

        let conversation = await assistant.startConversation(systemPrompt: systemPrompt)
        #expect(conversation.systemPrompt == systemPrompt)
    }

    @Test("Send message updates conversation")
    func sendMessageUpdatesConversation() async throws {
        let provider = MockIntelligenceProvider(responses: ["Mock response"])
        let assistant = ConversationalAssistant(provider: provider)

        _ = await assistant.startConversation()
        let response = try await assistant.sendMessage("Hello")

        #expect(!response.isEmpty)

        let history = try await assistant.conversationHistory()
        #expect(history.count == 2) // User message + assistant response
    }

    @Test("Send message without active conversation throws error")
    func sendMessageWithoutActiveConversationThrows() async {
        let provider = MockIntelligenceProvider()
        let assistant = ConversationalAssistant(provider: provider)

        await #expect(throws: IntelligenceError.noActiveConversation) {
            try await assistant.sendMessage("Hello")
        }
    }

    @Test("End conversation clears active conversation")
    func endConversationClears() async {
        let provider = MockIntelligenceProvider()
        let assistant = ConversationalAssistant(provider: provider)

        _ = await assistant.startConversation()
        await assistant.endConversation()

        let current = await assistant.currentConversation()
        #expect(current == nil)
    }
}
