//
//  OpenAICompatibleAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Foundation

/// Internal protocol abstracting HTTP communication with OpenAI-compatible APIs.
///
/// Enables mocking in tests without touching ARCNetworking or URLSession.
/// Used by both `OpenAIProvider` and `GrokProvider`.
protocol OpenAICompatibleAPIClient: Sendable {
    /// Send a chat completion request and receive a complete response.
    ///
    /// - Parameter request: The chat completion request.
    /// - Returns: The complete chat response.
    /// - Throws: `IntelligenceError` on failure.
    func sendChatCompletion(_ request: OpenAIChatRequest) async throws -> OpenAIChatResponse

    /// Send a chat completion request and receive a streaming response.
    ///
    /// - Parameter request: The chat completion request (must have `stream: true`).
    /// - Returns: An async stream of streaming chunks.
    func streamChatCompletion(_ request: OpenAIChatRequest) -> AsyncThrowingStream<OpenAIStreamChunk, Error>
}
