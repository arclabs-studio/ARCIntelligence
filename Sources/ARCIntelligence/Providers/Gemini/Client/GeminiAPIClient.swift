//
//  GeminiAPIClient.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Foundation

/// Internal protocol abstracting HTTP communication with the Gemini API.
///
/// Enables mocking in tests without touching ARCNetworking or URLSession.
protocol GeminiAPIClient: Sendable {
    /// Send a generateContent request and receive a complete response.
    ///
    /// - Parameter request: The generate content request.
    /// - Returns: The complete generate content response.
    /// - Throws: `IntelligenceError` on failure.
    func generateContent(_ request: GeminiGenerateContentRequest) async throws -> GeminiGenerateContentResponse

    /// Send a generateContent request and receive a streaming response.
    ///
    /// Each element in the stream is a complete `GeminiGenerateContentResponse`
    /// carrying partial text or a final chunk with `finishReason` set.
    ///
    /// - Parameter request: The generate content request.
    /// - Returns: An async stream of response chunks.
    func streamGenerateContent(_ request: GeminiGenerateContentRequest)
        -> AsyncThrowingStream<GeminiGenerateContentResponse, Error>
}
