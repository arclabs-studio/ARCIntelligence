//
//  ModelAvailability.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Foundation

/// Represents the availability status of an AI model.
///
/// This enum provides detailed information about why a model might be unavailable,
/// allowing apps to provide appropriate feedback to users.
public enum ModelAvailability: Sendable, Equatable {
    /// The model is available and ready to use
    case available

    /// The model is unavailable for a specific reason
    case unavailable(UnavailabilityReason)

    /// Reasons why a model might be unavailable.
    public enum UnavailabilityReason: Sendable, Equatable {
        /// The device does not support the AI capabilities required
        case deviceNotEligible

        /// Apple Intelligence is not enabled in device settings
        case appleIntelligenceNotEnabled

        /// The model is downloading or initializing
        case modelNotReady

        /// The required platform version is not met
        case unsupportedPlatform

        /// An unknown reason prevented availability
        case unknown(String)
    }

    /// Whether the model is available for use.
    public var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    /// Converts the unavailability reason to an appropriate `IntelligenceError`.
    ///
    /// - Returns: The corresponding error, or `nil` if the model is available.
    public func toError() -> IntelligenceError? {
        switch self {
        case .available:
            nil
        case let .unavailable(reason):
            switch reason {
            case .deviceNotEligible:
                .deviceNotEligible
            case .appleIntelligenceNotEnabled:
                .appleIntelligenceDisabled
            case .modelNotReady:
                .modelNotReady
            case .unsupportedPlatform:
                .providerUnavailable
            case let .unknown(message):
                .requestFailed(message)
            }
        }
    }
}
