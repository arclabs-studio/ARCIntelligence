//
//  TokenCounter.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Utility for estimating token counts in text.
///
/// Provides rough token estimation for planning API calls and managing context windows.
/// Uses a simple heuristic: ~4 characters per token (standard for English text).
public struct TokenCounter: Sendable {

    // MARK: - Constants

    private enum Constants {
        static let charactersPerToken: Int = 4
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Estimate token count for a single text
    /// - Parameter text: The input text
    /// - Returns: Estimated token count
    public func estimateTokens(for text: String) -> Int {
        max(1, text.count / Constants.charactersPerToken)
    }

    /// Estimate token count for multiple texts
    /// - Parameter texts: Array of texts
    /// - Returns: Total estimated token count
    public func estimateTokens(for texts: [String]) -> Int {
        texts.reduce(0) { $0 + estimateTokens(for: $1) }
    }

    /// Estimate token count for a conversation
    /// - Parameter conversation: The conversation to analyze
    /// - Returns: Estimated token count including all messages
    public func estimateTokens(for conversation: Conversation) -> Int {
        var total = 0

        // System prompt tokens
        if let systemPrompt = conversation.systemPrompt {
            total += estimateTokens(for: systemPrompt)
        }

        // Message tokens
        total += conversation.messages.reduce(0) { count, message in
            count + estimateTokens(for: message.content)
        }

        return total
    }

    /// Estimate token count for a message
    /// - Parameter message: The message to analyze
    /// - Returns: Estimated token count
    public func estimateTokens(for message: Message) -> Int {
        estimateTokens(for: message.content)
    }

    /// Check if text fits within a token limit
    /// - Parameters:
    ///   - text: The text to check
    ///   - limit: The token limit
    /// - Returns: True if text fits within limit
    public func fitsWithinLimit(_ text: String, limit: Int) -> Bool {
        estimateTokens(for: text) <= limit
    }

    /// Truncate text to fit within a token limit
    /// - Parameters:
    ///   - text: The text to truncate
    ///   - limit: The token limit
    /// - Returns: Truncated text that fits within the limit
    public func truncate(_ text: String, toLimit limit: Int) -> String {
        let estimatedTokens = estimateTokens(for: text)
        guard estimatedTokens > limit else {
            return text
        }

        let targetCharacters = limit * Constants.charactersPerToken
        guard targetCharacters < text.count else {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: targetCharacters)
        return String(text[..<endIndex]) + "..."
    }

    // MARK: - Static Helpers

    /// Quick estimation of token count for a text
    /// - Parameter text: The input text
    /// - Returns: Estimated token count
    public static func estimate(_ text: String) -> Int {
        TokenCounter().estimateTokens(for: text)
    }

    /// Quick check if text fits within limit
    /// - Parameters:
    ///   - text: The text to check
    ///   - limit: The token limit
    /// - Returns: True if text fits within limit
    public static func fits(_ text: String, within limit: Int) -> Bool {
        TokenCounter().fitsWithinLimit(text, limit: limit)
    }
}
