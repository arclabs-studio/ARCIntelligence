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

    // MARK: - Apple Foundation Models Specific Errors

    /// Content violated Apple's safety guardrails
    case guardrailViolation(String)

    /// Model refused to generate content for the given prompt
    case modelRefusal(String)

    /// Context window size exceeded (iOS 26+ Foundation Models limit: 4096 tokens)
    case contextWindowExceeded(used: Int, limit: Int)

    /// Apple Intelligence is not enabled on this device
    case appleIntelligenceDisabled

    /// Device does not support Apple Intelligence
    case deviceNotEligible

    /// Model is not ready (downloading or other system reasons)
    case modelNotReady

    public var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            "The AI provider is not available on this device."
        case let .providerNotConfigured(name):
            "Provider '\(name)' is not properly configured."
        case let .invalidRequest(reason):
            "Invalid request: \(reason)"
        case let .requestFailed(reason):
            "Request failed: \(reason)"
        case let .responseParseFailed(reason):
            "Failed to parse response: \(reason)"
        case .rateLimitExceeded:
            "Rate limit exceeded. Please try again later."
        case .authenticationFailed:
            "Authentication failed. Please check your credentials."
        case let .tokenLimitExceeded(current, max):
            "Token limit exceeded (\(current)/\(max))."
        case .noActiveConversation:
            "No active conversation. Start a new conversation first."
        case let .unknown(error):
            "An unexpected error occurred: \(error.localizedDescription)"
        case let .guardrailViolation(details):
            "Content violated safety guidelines: \(details)"
        case let .modelRefusal(reason):
            "The model declined to generate content: \(reason)"
        case let .contextWindowExceeded(used, limit):
            "Context window exceeded (\(used)/\(limit) tokens)."
        case .appleIntelligenceDisabled:
            "Apple Intelligence is not enabled. Please enable it in Settings."
        case .deviceNotEligible:
            "This device does not support Apple Intelligence."
        case .modelNotReady:
            "The AI model is not ready. It may be downloading or initializing."
        }
    }

    // MARK: - Equatable

    // swiftlint:disable:next cyclomatic_complexity
    public static func == (lhs: IntelligenceError, rhs: IntelligenceError) -> Bool {
        switch (lhs, rhs) {
        case (.providerUnavailable, .providerUnavailable):
            true
        case let (.providerNotConfigured(lhsName), .providerNotConfigured(rhsName)):
            lhsName == rhsName
        case let (.invalidRequest(lhsReason), .invalidRequest(rhsReason)):
            lhsReason == rhsReason
        case let (.requestFailed(lhsReason), .requestFailed(rhsReason)):
            lhsReason == rhsReason
        case let (.responseParseFailed(lhsReason), .responseParseFailed(rhsReason)):
            lhsReason == rhsReason
        case (.rateLimitExceeded, .rateLimitExceeded):
            true
        case (.authenticationFailed, .authenticationFailed):
            true
        case let (.tokenLimitExceeded(lhsCurrent, lhsMax), .tokenLimitExceeded(rhsCurrent, rhsMax)):
            lhsCurrent == rhsCurrent && lhsMax == rhsMax
        case (.noActiveConversation, .noActiveConversation):
            true
        case let (.unknown(lhsError), .unknown(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        case let (.guardrailViolation(lhsDetails), .guardrailViolation(rhsDetails)):
            lhsDetails == rhsDetails
        case let (.modelRefusal(lhsReason), .modelRefusal(rhsReason)):
            lhsReason == rhsReason
        case let (.contextWindowExceeded(lhsUsed, lhsLimit), .contextWindowExceeded(rhsUsed, rhsLimit)):
            lhsUsed == rhsUsed && lhsLimit == rhsLimit
        case (.appleIntelligenceDisabled, .appleIntelligenceDisabled):
            true
        case (.deviceNotEligible, .deviceNotEligible):
            true
        case (.modelNotReady, .modelNotReady):
            true
        default:
            false
        }
    }
}
