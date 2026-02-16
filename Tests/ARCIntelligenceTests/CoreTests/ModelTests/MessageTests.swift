//
//  MessageTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation
import Testing
@testable import ARCIntelligence

@Suite("Message Tests")
struct MessageTests {
    @Test("Message initializes with default values")
    func messageInitializesWithDefaults() {
        let message = Message(role: .user,
                              content: "Hello")

        #expect(message.role == .user)
        #expect(message.content == "Hello")
        #expect(message.metadata.isEmpty)
    }

    @Test("Message initializes with custom values")
    func messageInitializesWithCustomValues() {
        let id = UUID()
        let timestamp = Date()
        let metadata = ["key": "value"]

        let message = Message(id: id,
                              role: .assistant,
                              content: "Response",
                              timestamp: timestamp,
                              metadata: metadata)

        #expect(message.id == id)
        #expect(message.role == .assistant)
        #expect(message.content == "Response")
        #expect(message.timestamp == timestamp)
        #expect(message.metadata == metadata)
    }

    @Test("Message roles are correctly defined")
    func messageRolesAreCorrect() {
        #expect(Message.Role.user.rawValue == "user")
        #expect(Message.Role.assistant.rawValue == "assistant")
        #expect(Message.Role.system.rawValue == "system")
    }
}
