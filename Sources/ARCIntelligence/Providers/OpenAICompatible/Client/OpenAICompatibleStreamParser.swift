//
//  OpenAICompatibleStreamParser.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

/// Parser for OpenAI-compatible Server-Sent Events (SSE) streaming responses.
///
/// Processes raw `data: {...}` lines from the SSE stream and emits
/// typed `OpenAIStreamChunk` values.
struct OpenAICompatibleStreamParser: Sendable {
    /// Parse a stream of line-delimited data chunks into stream chunks.
    ///
    /// - Parameter dataStream: An `AsyncThrowingStream` where each element is one SSE line.
    /// - Returns: An async stream of parsed chunks.
    func parse(_ dataStream: AsyncThrowingStream<Data, Error>) -> AsyncThrowingStream<OpenAIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await lineData in dataStream {
                        let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
                        if let chunk = try parseLine(line) {
                            continuation.yield(chunk)
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
    /// - Returns: A parsed chunk, or nil if the line is not a data line.
    func parseLine(_ line: String) throws -> OpenAIStreamChunk? {
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

        return try JSONDecoder().decode(OpenAIStreamChunk.self, from: data)
    }
}
