//
//  OpenAICompatibleStreamParserTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/03/2026.
//

import Foundation
import Testing
@testable import ARCIntelligence

@Suite("OpenAI Compatible Stream Parser Tests", .tags(.unit)) struct OpenAICompatibleStreamParserTests {
    // MARK: - Helpers

    private func makeSUT() -> OpenAICompatibleStreamParser {
        OpenAICompatibleStreamParser()
    }

    // MARK: - Line Filtering

    @Test("Should return nil for non-data lines") func returnsNilForNonDataLines() throws {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(try sut.parseLine("event: delta") == nil)
        #expect(try sut.parseLine("") == nil)
        #expect(try sut.parseLine(": keep-alive") == nil)
    }

    @Test("Should return nil for data: [DONE] sentinel") func returnsNilForDoneSentinel() throws {
        // Given
        let sut = makeSUT()

        // When
        let result = try sut.parseLine("data: [DONE]")

        // Then
        #expect(result == nil)
    }

    @Test("Should return nil for empty data after prefix") func returnsNilForEmptyDataAfterPrefix() throws {
        // Given
        let sut = makeSUT()

        // When
        let result = try sut.parseLine("data: ")

        // Then
        #expect(result == nil)
    }

    // MARK: - Chunk Parsing

    @Test("Should parse a valid stream chunk with content delta") func parsesValidChunkWithContentDelta() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable:next line_length
        let line = #"data: {"id":"chatcmpl-test","object":"chat.completion.chunk","model":"gpt-4o","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        #expect(result != nil)
        #expect(result?.choices?.first?.delta.content == "Hello")
        #expect(result?.choices?.first?.finishReason == nil)
    }

    @Test("Should parse a valid stream chunk with finish reason") func parsesChunkWithFinishReason() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable:next line_length
        let line = #"data: {"id":"chatcmpl-test","object":"chat.completion.chunk","model":"gpt-4o","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        #expect(result?.choices?.first?.finishReason == "stop")
    }

    @Test("Should parse a chunk with empty delta") func parsesChunkWithEmptyDelta() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable:next line_length
        let line = #"data: {"id":"chatcmpl-test","object":"chat.completion.chunk","model":"gpt-4o","choices":[{"index":0,"delta":{},"finish_reason":null}]}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        #expect(result != nil)
        #expect(result?.choices?.first?.delta.content == nil)
    }

    @Test("Should parse chunk id correctly") func parsesChunkId() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"id":"chatcmpl-abc123","object":"chat.completion.chunk","choices":[]}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        #expect(result?.id == "chatcmpl-abc123")
    }

    // MARK: - Error Handling

    @Test("Should throw on malformed JSON") func throwsOnMalformedJSON() {
        // Given
        let sut = makeSUT()
        let line = #"data: {"id":"test" INVALID_JSON"#

        // When / Then
        #expect(throws: (any Error).self) {
            try sut.parseLine(line)
        }
    }

    @Test("Should throw on completely invalid JSON structure") func throwsOnInvalidJSONStructure() {
        // Given
        let sut = makeSUT()
        let line = #"data: not-json-at-all"#

        // When / Then
        #expect(throws: (any Error).self) {
            try sut.parseLine(line)
        }
    }
}
