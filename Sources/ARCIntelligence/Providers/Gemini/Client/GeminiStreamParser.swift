//
//  GeminiStreamParser.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

/// Parser for Gemini Server-Sent Events (SSE) streaming responses.
///
/// The Gemini streaming API (`streamGenerateContent?alt=sse`) emits one complete
/// `GeminiGenerateContentResponse` JSON object per `data:` line. Unlike the
/// Anthropic or OpenAI parsers, there are no event type envelopes — each line
/// is directly decodable as the response type.
struct GeminiStreamParser {
    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
    }

    /// Parse a stream of raw SSE data into complete response chunks.
    ///
    /// - Parameter dataStream: An `AsyncThrowingStream` where each element is one SSE line.
    /// - Returns: An async stream of parsed `GeminiGenerateContentResponse` values.
    func parse(_ dataStream: AsyncThrowingStream<Data, Error>)
    -> AsyncThrowingStream<GeminiGenerateContentResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await lineData in dataStream {
                        let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
                        if let response = try parseLine(line) {
                            continuation.yield(response)

                            // Finish when the model signals it has completed
                            if let finishReason = response.candidates?.first?.finishReason,
                               !finishReason.isEmpty {
                                continuation.finish()
                                return
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

    /// Parse a single SSE line into a response, or return nil for non-data lines.
    ///
    /// - Parameter line: The raw SSE line.
    /// - Returns: A decoded response, or nil if the line is skipped.
    func parseLine(_ line: String) throws -> GeminiGenerateContentResponse? {
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

        return try decoder.decode(GeminiGenerateContentResponse.self, from: data)
    }
}
