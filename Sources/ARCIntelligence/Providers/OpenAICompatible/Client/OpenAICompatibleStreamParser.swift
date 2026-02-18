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
    /// Parse a sequence of raw bytes into stream chunks.
    ///
    /// - Parameter bytes: The async byte sequence from URLSession.
    /// - Returns: An async stream of parsed chunks.
    func parse(_ bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<OpenAIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var buffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        buffer.append(char)

                        if char == "\n" {
                            let line = buffer.trimmingCharacters(in: .newlines)
                            buffer = ""

                            if let chunk = try parseLine(line) {
                                continuation.yield(chunk)
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
