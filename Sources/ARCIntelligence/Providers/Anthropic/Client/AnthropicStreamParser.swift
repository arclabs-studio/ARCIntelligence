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
    func parse(
        _ bytes: URLSession.AsyncBytes
    ) -> AsyncThrowingStream<AnthropicStreamEvent, Error> {
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

    /// Parse a single SSE line.
    ///
    /// - Parameter line: The raw SSE line.
    /// - Returns: A parsed event, or nil if the line is not a data line.
    // swiftlint:disable:next cyclomatic_complexity
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

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
            return nil
        }

        switch type {
        case "message_start":
            let wrapper = try decoder.decode(MessageStartWrapper.self, from: data)
            return .messageStart(wrapper.message)

        case "content_block_start":
            return try parseContentBlockStart(json: json, data: data)

        case "content_block_delta":
            return try parseContentBlockDelta(json: json)

        case "content_block_stop":
            let index = json["index"] as? Int ?? 0
            return .contentBlockStop(index: index)

        case "message_delta":
            return parseMessageDelta(json: json)

        case "message_stop":
            return .messageStop

        case "ping":
            return .ping

        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    private func parseContentBlockStart(
        json: [String: Any],
        data: Data
    ) throws -> AnthropicStreamEvent? {
        let index = json["index"] as? Int ?? 0
        let wrapper = try decoder.decode(ContentBlockStartWrapper.self, from: data)
        return .contentBlockStart(index: index, wrapper.contentBlock)
    }

    private func parseContentBlockDelta(json: [String: Any]) throws -> AnthropicStreamEvent? {
        let index = json["index"] as? Int ?? 0

        guard let delta = json["delta"] as? [String: Any],
              let deltaType = delta["type"] as? String
        else {
            return nil
        }

        switch deltaType {
        case "text_delta":
            let text = delta["text"] as? String ?? ""
            return .contentBlockDelta(index: index, text: text)

        case "input_json_delta":
            let partialJson = delta["partial_json"] as? String ?? ""
            return .toolUseDelta(index: index, partialJson: partialJson)

        default:
            return nil
        }
    }

    private func parseMessageDelta(json: [String: Any]) -> AnthropicStreamEvent? {
        let delta = json["delta"] as? [String: Any]
        let stopReason = delta?["stop_reason"] as? String

        var usage: AnthropicUsage?
        if let usageDict = json["usage"] as? [String: Any] {
            let outputTokens = usageDict["output_tokens"] as? Int ?? 0
            usage = AnthropicUsage(
                inputTokens: usageDict["input_tokens"] as? Int ?? 0,
                outputTokens: outputTokens
            )
        }

        return .messageDelta(stopReason: stopReason, usage: usage)
    }
}

// MARK: - Decoding Wrappers

private struct MessageStartWrapper: Decodable {
    let message: AnthropicMessageResponse
}

private struct ContentBlockStartWrapper: Decodable {
    let contentBlock: AnthropicResponseContentBlock

    enum CodingKeys: String, CodingKey {
        case contentBlock = "content_block"
    }
}
