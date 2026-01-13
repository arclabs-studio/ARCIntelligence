//
//  IntelligenceError.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Errors that can occur when using ARCIntelligence providers.
public enum IntelligenceError: LocalizedError, Sendable, Equatable {

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

    // MARK: - Equatable

    public static func == (lhs: IntelligenceError, rhs: IntelligenceError) -> Bool {
        switch (lhs, rhs) {
        case (.providerUnavailable, .providerUnavailable):
            return true
        case (.providerNotConfigured(let lhsName), .providerNotConfigured(let rhsName)):
            return lhsName == rhsName
        case (.invalidRequest(let lhsReason), .invalidRequest(let rhsReason)):
            return lhsReason == rhsReason
        case (.requestFailed(let lhsReason), .requestFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.responseParseFailed(let lhsReason), .responseParseFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.rateLimitExceeded, .rateLimitExceeded):
            return true
        case (.authenticationFailed, .authenticationFailed):
            return true
        case (.tokenLimitExceeded(let lhsCurrent, let lhsMax), .tokenLimitExceeded(let rhsCurrent, let rhsMax)):
            return lhsCurrent == rhsCurrent && lhsMax == rhsMax
        case (.noActiveConversation, .noActiveConversation):
            return true
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
