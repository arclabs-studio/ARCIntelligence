//
//  AnthropicStreamParser.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation

/// Parser for Anthropic Server-Sent Events (SSE) streaming responses.
///
/// Processes raw `data: {...}` lines from the SSE stream and emits
/// typed `AnthropicStreamEvent` values.
struct AnthropicStreamParser: Sendable {
    private let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /// Parse a sequence of raw bytes into stream events.
    ///
    /// - Parameter bytes: The async byte sequence from URLSession.
    /// - Returns: An async stream of parsed events.
    func parse(_ bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<AnthropicStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var buffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        buffer.append(char)

                        // SSE lines are delimited by newlines
                        if char == "\n" {
                            let line = buffer.trimmingCharacters(in: .newlines)
                            buffer = ""

                            if let event = try parseLine(line) {
                                continuation.yield(event)

                                if case .messageStop = event {
                                    continuation.finish()
                                    return
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity
    /// Parse a single SSE line.
    ///
    /// - Parameter line: The raw SSE line.
    /// - Returns: A parsed event, or nil if the line is not a data line.
    func parseLine(_ line: String) throws -> AnthropicStreamEvent? {
        guard line.hasPrefix("data: ") else {
            return nil
        }

        let jsonString = String(line.dropFirst(6))

        guard !jsonString.isEmpty, jsonString != "[DONE]" else {
            return nil
        }

        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        let envelope = try decoder.decode(StreamEventEnvelope.self, from: data)

        switch envelope.type {
        case "message_start":
            let wrapper = try decoder.decode(MessageStartWrapper.self, from: data)
            return .messageStart(wrapper.message)

        case "content_block_start":
            let wrapper = try decoder.decode(ContentBlockStartWrapper.self, from: data)
            return .contentBlockStart(index: wrapper.index, wrapper.contentBlock)

        case "content_block_delta":
            let wrapper = try decoder.decode(ContentBlockDeltaWrapper.self, from: data)
            return wrapper.toEvent()

        case "content_block_stop":
            return .contentBlockStop(index: envelope.index ?? 0)

        case "message_delta":
            let wrapper = try decoder.decode(MessageDeltaWrapper.self, from: data)
            return .messageDelta(stopReason: wrapper.delta?.stopReason, usage: wrapper.usage)

        case "message_stop":
            return .messageStop

        case "ping":
            return .ping

        default:
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Decodable Wrappers

/// Lightweight envelope to route events by type without JSONSerialization.
private struct StreamEventEnvelope: Decodable {
    let type: String
    let index: Int?
}

private struct MessageStartWrapper: Decodable {
    let message: AnthropicMessageResponse
}

private struct ContentBlockStartWrapper: Decodable {
    let index: Int
    let contentBlock: AnthropicResponseContentBlock

    enum CodingKeys: String, CodingKey {
        case index
        case contentBlock = "content_block"
    }
}

private struct ContentBlockDeltaPayload: Decodable {
    let type: String
    let text: String?
    let partialJson: String?

    enum CodingKeys: String, CodingKey {
        case type, text
        case partialJson = "partial_json"
    }
}

private struct ContentBlockDeltaWrapper: Decodable {
    let index: Int
    let delta: ContentBlockDeltaPayload

    func toEvent() -> AnthropicStreamEvent? {
        switch delta.type {
        case "text_delta":
            .contentBlockDelta(index: index, text: delta.text ?? "")
        case "input_json_delta":
            .toolUseDelta(index: index, partialJson: delta.partialJson ?? "")
        default:
            nil
        }
    }
}

private struct MessageDeltaPayload: Decodable {
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case stopReason = "stop_reason"
    }
}

private struct MessageDeltaWrapper: Decodable {
    let delta: MessageDeltaPayload?
    let usage: AnthropicUsage?
}
