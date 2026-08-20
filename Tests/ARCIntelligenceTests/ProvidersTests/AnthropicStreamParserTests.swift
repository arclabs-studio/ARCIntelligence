//
//  AnthropicStreamParserTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/03/2026.
//

import Foundation
import Testing
@testable import ARCIntelligence

@Suite("Anthropic Stream Parser Tests", .tags(.unit)) struct AnthropicStreamParserTests {
    // MARK: - Helpers

    private func makeSUT() -> AnthropicStreamParser {
        AnthropicStreamParser()
    }

    // MARK: - Line Filtering

    @Test("Should return nil for non-data lines") func returnsNilForNonDataLines() throws {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(try sut.parseLine("event: message_start") == nil)
        #expect(try sut.parseLine("") == nil)
        #expect(try sut.parseLine(": ping") == nil)
        #expect(try sut.parseLine("id: 123") == nil)
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

    @Test("Should return nil for unknown event types") func returnsNilForUnknownEventType() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"unknown_future_event","data":{}}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        #expect(result == nil)
    }

    // MARK: - Event Parsing

    @Test("Should parse message_stop event") func parsesMessageStop() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"message_stop"}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case .messageStop = result else {
            Issue.record("Expected messageStop, got \(String(describing: result))")
            return
        }
    }

    @Test("Should parse ping event") func parsesPing() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"ping"}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case .ping = result else {
            Issue.record("Expected ping, got \(String(describing: result))")
            return
        }
    }

    @Test("Should parse content_block_stop event with index") func parsesContentBlockStop() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"content_block_stop","index":2}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case let .contentBlockStop(index) = result else {
            Issue.record("Expected contentBlockStop, got \(String(describing: result))")
            return
        }
        #expect(index == 2)
    }

    @Test("Should parse content_block_delta text_delta event") func parsesContentBlockDeltaTextDelta() throws {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case let .contentBlockDelta(index, text) = result else {
            Issue.record("Expected contentBlockDelta, got \(String(describing: result))")
            return
        }
        #expect(index == 0)
        #expect(text == "Hello")
    }

    @Test("Should parse content_block_delta input_json_delta event")
    func parsesContentBlockDeltaInputJsonDelta() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable:next line_length
        let line = #"data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"key\":"}}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case let .toolUseDelta(index, partialJson) = result else {
            Issue.record("Expected toolUseDelta, got \(String(describing: result))")
            return
        }
        #expect(index == 1)
        #expect(partialJson == #"{"key":"#)
    }

    @Test("Should parse message_delta event with stop reason") func parsesMessageDeltaWithStopReason() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable:next line_length
        let line = #"data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"input_tokens":10,"output_tokens":20}}"#

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case let .messageDelta(stopReason, usage) = result else {
            Issue.record("Expected messageDelta, got \(String(describing: result))")
            return
        }
        #expect(stopReason == "end_turn")
        #expect(usage?.inputTokens == 10)
        #expect(usage?.outputTokens == 20)
    }

    @Test("Should parse message_start event") func parsesMessageStart() throws {
        // Given
        let sut = makeSUT()
        // swiftlint:disable line_length
        let line = """
        data: {"type":"message_start","message":{"id":"msg_test","type":"message","model":"claude-sonnet-4-5","content":[],"stop_reason":null,"usage":{"input_tokens":10,"output_tokens":0}}}
        """
        // swiftlint:enable line_length

        // When
        let result = try sut.parseLine(line)

        // Then
        guard case let .messageStart(response) = result else {
            Issue.record("Expected messageStart, got \(String(describing: result))")
            return
        }
        #expect(response.id == "msg_test")
        #expect(response.model == "claude-sonnet-4-5")
    }

    // MARK: - Error Handling

    @Test("Should throw on malformed JSON") func throwsOnMalformedJSON() {
        // Given
        let sut = makeSUT()
        let line = #"data: {"type":"message_stop" INVALID"#

        // When / Then
        #expect(throws: (any Error).self) {
            try sut.parseLine(line)
        }
    }
}

// MARK: - AnthropicStreamEvent Equatable

extension AnthropicStreamEvent: Equatable {
    public static func == (lhs: AnthropicStreamEvent, rhs: AnthropicStreamEvent) -> Bool {
        switch (lhs, rhs) {
        case (.messageStop, .messageStop):
            true
        case (.ping, .ping):
            true
        case let (.contentBlockStop(lhs), .contentBlockStop(rhs)):
            lhs == rhs
        case let (.contentBlockDelta(li, lt), .contentBlockDelta(ri, rt)):
            li == ri && lt == rt
        case let (.toolUseDelta(li, lj), .toolUseDelta(ri, rj)):
            li == ri && lj == rj
        default:
            false
        }
    }
}
