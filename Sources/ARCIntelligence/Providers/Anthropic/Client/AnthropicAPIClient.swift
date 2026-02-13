//
//  AnthropicAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Foundation

/// Internal protocol abstracting HTTP communication with the Anthropic API.
///
/// Enables mocking in tests without touching ARCNetworking or URLSession.
protocol AnthropicAPIClient: Sendable {
    /// Send a message request and receive a complete response.
    ///
    /// - Parameter request: The message request.
    /// - Returns: The complete message response.
    /// - Throws: `IntelligenceError` on failure.
    func sendMessage(_ request: AnthropicMessageRequest) async throws -> AnthropicMessageResponse

    /// Send a message request and receive a streaming response.
    ///
    /// - Parameter request: The message request (must have `stream: true`).
    /// - Returns: An async stream of server-sent events.
    func streamMessage(_ request: AnthropicMessageRequest) -> AsyncThrowingStream<AnthropicStreamEvent, Error>
}
