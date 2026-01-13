//
//  IntelligenceError.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Errors that can occur when using ARCIntelligence providers.
public enum IntelligenceError: LocalizedError, Sendable {

    /// Provider is not available on this device/environment
    case providerUnavailable

    /// Provider is not configured properly
    case providerNotConfigured(String)

    /// Invalid request parameters
    case invalidRequest(String)

    /// API request failed
    case requestFailed(String)

    /// Response parsing failed
    case responseParseFailed(String)

    /// Rate limit exceeded
    case rateLimitExceeded

    /// Authentication failed
    case authenticationFailed

    /// Token limit exceeded
    case tokenLimitExceeded(current: Int, max: Int)

    /// No active conversation
    case noActiveConversation

    /// Unknown error occurred
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "The AI provider is not available on this device."
        case .providerNotConfigured(let name):
            return "Provider '\(name)' is not properly configured."
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .requestFailed(let reason):
            return "Request failed: \(reason)"
        case .responseParseFailed(let reason):
            return "Failed to parse response: \(reason)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .tokenLimitExceeded(let current, let max):
            return "Token limit exceeded (\(current)/\(max))."
        case .noActiveConversation:
            return "No active conversation. Start a new conversation first."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
