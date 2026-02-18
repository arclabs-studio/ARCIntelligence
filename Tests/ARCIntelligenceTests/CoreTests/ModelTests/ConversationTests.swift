//
//  ConversationTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Testing
@testable import ARCIntelligence

@Suite("Conversation Tests", .tags(.unit))
struct ConversationTests {
    @Test("Conversation initializes empty")
    func conversationInitializesEmpty() {
        let conversation = Conversation()

        #expect(conversation.messages.isEmpty)
        #expect(conversation.isEmpty)
        #expect(conversation.messageCount == 0)
    }

    @Test("Conversation tracks message count")
    func conversationTracksMessageCount() {
        var conversation = Conversation()

        #expect(conversation.messageCount == 0)

        conversation.messages.append(Message(role: .user, content: "Hello"))
        #expect(conversation.messageCount == 1)
        #expect(!conversation.isEmpty)

        conversation.messages.append(Message(role: .assistant, content: "Hi"))
        #expect(conversation.messageCount == 2)
    }

    @Test("Conversation with system prompt")
    func conversationWithSystemPrompt() {
        let systemPrompt = "You are a helpful assistant"
        let conversation = Conversation(systemPrompt: systemPrompt)

        #expect(conversation.systemPrompt == systemPrompt)
    }
}
