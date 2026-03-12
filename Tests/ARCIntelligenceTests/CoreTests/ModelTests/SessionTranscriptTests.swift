//
//  SessionTranscriptTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation
import Testing
@testable import ARCIntelligence

// MARK: - SessionTranscript Tests

@Suite("SessionTranscript Tests", .tags(.unit)) struct SessionTranscriptTests {
    // MARK: - Helpers

    private func makePrompt(id: String = "p1", content: String = "Hello") -> TranscriptPrompt {
        TranscriptPrompt(id: id, content: content, timestamp: .distantPast)
    }

    private func makeResponse(id: String = "r1", content: String = "Hi there") -> TranscriptResponse {
        TranscriptResponse(id: id, content: content, timestamp: .distantPast)
    }

    private func makeInstructions(id: String = "i1", content: String = "Be helpful") -> TranscriptInstructions {
        TranscriptInstructions(id: id, content: content, timestamp: .distantPast)
    }

    private func makeToolCall(id: String = "tc1", toolName: String = "weather") -> TranscriptToolCall {
        TranscriptToolCall(id: id, toolName: toolName, arguments: ["city": "Paris"], timestamp: .distantPast)
    }

    private func makeToolOutput(id: String = "to1",
                                toolCallId: String = "tc1",
                                content: String = "Sunny 20°C") -> TranscriptToolOutput {
        TranscriptToolOutput(id: id, toolCallId: toolCallId, content: content, timestamp: .distantPast)
    }

    private func makeSUT(entries: [TranscriptEntry] = []) -> SessionTranscript {
        SessionTranscript(entries: entries)
    }

    // MARK: - Initialization

    @Test("empty init produces empty transcript", .tags(.unit)) func emptyInit_producesEmptyTranscript() {
        // Given / When
        let sut = SessionTranscript()

        // Then
        #expect(sut.isEmpty)
        #expect(sut.entries.isEmpty)
    }

    @Test("init with entries stores entries in order", .tags(.unit)) func initWithEntries_storesEntriesInOrder() {
        // Given
        let entries: [TranscriptEntry] = [.prompt(makePrompt()),
                                          .response(makeResponse())]

        // When
        let sut = makeSUT(entries: entries)

        // Then
        #expect(sut.count == 2)
        #expect(!sut.isEmpty)
    }

    // MARK: - Computed Properties

    @Test("first returns first entry", .tags(.unit)) func first_returnsFirstEntry() {
        // Given
        let prompt = makePrompt(id: "first")
        let sut = makeSUT(entries: [.prompt(prompt), .response(makeResponse())])

        // When / Then
        if case let .prompt(entry) = sut.first {
            #expect(entry.id == "first")
        } else {
            Issue.record("Expected .prompt as first entry")
        }
    }

    @Test("last returns last entry", .tags(.unit)) func last_returnsLastEntry() {
        // Given
        let response = makeResponse(id: "last")
        let sut = makeSUT(entries: [.prompt(makePrompt()), .response(response)])

        // When / Then
        if case let .response(entry) = sut.last {
            #expect(entry.id == "last")
        } else {
            Issue.record("Expected .response as last entry")
        }
    }

    @Test("first and last are nil on empty transcript", .tags(.unit)) func firstAndLast_areNilWhenEmpty() {
        // Given
        let sut = SessionTranscript()

        // When / Then
        #expect(sut.first == nil)
        #expect(sut.last == nil)
    }

    @Test("prompts returns only prompt entries", .tags(.unit)) func prompts_returnsOnlyPromptEntries() {
        // Given
        let sut = makeSUT(entries: [.instructions(makeInstructions()),
                                    .prompt(makePrompt(id: "p1")),
                                    .response(makeResponse()),
                                    .prompt(makePrompt(id: "p2"))])

        // When
        let prompts = sut.prompts

        // Then
        #expect(prompts.count == 2)
        #expect(prompts.map(\.id) == ["p1", "p2"])
    }

    @Test("responses returns only response entries", .tags(.unit)) func responses_returnsOnlyResponseEntries() {
        // Given
        let sut = makeSUT(entries: [.prompt(makePrompt()),
                                    .response(makeResponse(id: "r1")),
                                    .toolCall(makeToolCall()),
                                    .response(makeResponse(id: "r2"))])

        // When
        let responses = sut.responses

        // Then
        #expect(responses.count == 2)
        #expect(responses.map(\.id) == ["r1", "r2"])
    }

    @Test("toolCalls returns only toolCall entries", .tags(.unit)) func toolCalls_returnsOnlyToolCallEntries() {
        // Given
        let sut = makeSUT(entries: [.prompt(makePrompt()),
                                    .toolCall(makeToolCall(id: "tc1", toolName: "weather")),
                                    .toolOutput(makeToolOutput()),
                                    .toolCall(makeToolCall(id: "tc2", toolName: "search"))])

        // When
        let toolCalls = sut.toolCalls

        // Then
        #expect(toolCalls.count == 2)
        #expect(toolCalls.map(\.toolName) == ["weather", "search"])
    }

    // MARK: - Subscript

    @Test("subscript accesses entry by index", .tags(.unit)) func subscript_accessesEntryByIndex() {
        // Given
        let prompt = makePrompt(id: "target")
        let sut = makeSUT(entries: [.response(makeResponse()), .prompt(prompt)])

        // When
        let entry = sut[1]

        // Then
        if case let .prompt(value) = entry {
            #expect(value.id == "target")
        } else {
            Issue.record("Expected .prompt at index 1")
        }
    }

    // MARK: - RandomAccessCollection

    @Test("startIndex is 0", .tags(.unit)) func startIndex_isZero() {
        // Given
        let sut = makeSUT(entries: [.prompt(makePrompt())])

        // When / Then
        #expect(sut.startIndex == 0)
    }

    @Test("endIndex equals count", .tags(.unit)) func endIndex_equalsCount() {
        // Given
        let sut = makeSUT(entries: [.prompt(makePrompt()), .response(makeResponse())])

        // When / Then
        #expect(sut.endIndex == sut.count)
    }

    @Test("can iterate with for-in", .tags(.unit)) func collection_canIterateWithForIn() {
        // Given
        let sut = makeSUT(entries: [.prompt(makePrompt(id: "p")), .response(makeResponse(id: "r"))])
        var ids: [String] = []

        // When
        for entry in sut {
            ids.append(entry.id)
        }

        // Then
        #expect(ids == ["p", "r"])
    }

    // MARK: - Equatable

    @Test("transcripts with same entries are equal", .tags(.unit)) func equatable_sameEntriesAreEqual() {
        // Given
        let entries: [TranscriptEntry] = [.prompt(makePrompt()), .response(makeResponse())]
        let first = makeSUT(entries: entries)
        let second = makeSUT(entries: entries)

        // When / Then
        #expect(first == second)
    }

    @Test("transcripts with different entries are not equal", .tags(.unit))
    func equatable_differentEntriesAreNotEqual() {
        // Given
        let first = makeSUT(entries: [.prompt(makePrompt(id: "x"))])
        let second = makeSUT(entries: [.prompt(makePrompt(id: "y"))])

        // When / Then
        #expect(first != second)
    }

    // MARK: - TranscriptEntry.id

    @Test("TranscriptEntry id delegates to wrapped value id", .tags(.unit))
    func transcriptEntry_idDelegatesToWrappedId() {
        // Given
        let entries: [TranscriptEntry] = [.instructions(makeInstructions(id: "i")),
                                          .prompt(makePrompt(id: "p")),
                                          .response(makeResponse(id: "r")),
                                          .toolCall(makeToolCall(id: "tc")),
                                          .toolOutput(makeToolOutput(id: "to"))]

        // When / Then
        #expect(entries[0].id == "i")
        #expect(entries[1].id == "p")
        #expect(entries[2].id == "r")
        #expect(entries[3].id == "tc")
        #expect(entries[4].id == "to")
    }

    // MARK: - Codable: SessionTranscript round-trip

    @Test("SessionTranscript codable round-trip preserves all entries", .tags(.unit))
    func sessionTranscript_codableRoundTrip() throws {
        // Given
        let sut = makeSUT(entries: [.instructions(makeInstructions()),
                                    .prompt(makePrompt()),
                                    .response(makeResponse()),
                                    .toolCall(makeToolCall()),
                                    .toolOutput(makeToolOutput())])

        // When
        let data = try JSONEncoder().encode(sut)
        let decoded = try JSONDecoder().decode(SessionTranscript.self, from: data)

        // Then
        #expect(decoded == sut)
        #expect(decoded.count == 5)
    }

    // MARK: - Codable: TranscriptEntry round-trip per case

    @Test("TranscriptEntry instructions round-trips correctly", .tags(.unit))
    func transcriptEntry_instructionsRoundTrip() throws {
        // Given
        let entry = TranscriptEntry.instructions(makeInstructions(id: "i1", content: "Be concise"))

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)

        // Then
        #expect(decoded == entry)
    }

    @Test("TranscriptEntry prompt round-trips correctly", .tags(.unit)) func transcriptEntry_promptRoundTrip() throws {
        // Given
        let entry = TranscriptEntry.prompt(makePrompt(id: "p99", content: "What is Swift?"))

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)

        // Then
        #expect(decoded == entry)
    }

    @Test("TranscriptEntry response round-trips correctly", .tags(.unit))
    func transcriptEntry_responseRoundTrip() throws {
        // Given
        let entry = TranscriptEntry.response(makeResponse(id: "r99", content: "Swift is great"))

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)

        // Then
        #expect(decoded == entry)
    }

    @Test("TranscriptEntry toolCall round-trips correctly", .tags(.unit))
    func transcriptEntry_toolCallRoundTrip() throws {
        // Given
        let entry = TranscriptEntry.toolCall(makeToolCall(id: "tc99", toolName: "calc"))

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)

        // Then
        #expect(decoded == entry)
    }

    @Test("TranscriptEntry toolOutput round-trips correctly", .tags(.unit))
    func transcriptEntry_toolOutputRoundTrip() throws {
        // Given
        let entry = TranscriptEntry.toolOutput(makeToolOutput(id: "to99", content: "42"))

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)

        // Then
        #expect(decoded == entry)
    }

    @Test("TranscriptEntry decode with unknown type throws", .tags(.unit))
    func transcriptEntry_decodeUnknownTypeThrows() throws {
        // Given
        let json = "{\"type\":\"unknown\",\"value\":{\"id\":\"x\",\"content\":\"y\",\"timestamp\":0}}"
        let data = try #require(json.data(using: .utf8))

        // When / Then
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TranscriptEntry.self, from: data)
        }
    }
}
