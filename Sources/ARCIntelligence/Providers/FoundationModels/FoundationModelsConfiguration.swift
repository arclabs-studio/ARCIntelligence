//
//  FoundationModelsConfiguration.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Foundation

/// Configuration for the Foundation Models provider.
public struct FoundationModelsConfiguration: Sendable, Equatable {

    // MARK: - Properties

    /// Default temperature for completions
    public let defaultTemperature: Float

    /// Maximum tokens per request
    public let maxTokensPerRequest: Int

    /// Enable on-device processing only (no cloud fallback)
    public let onDeviceOnly: Bool

    // MARK: - Initialization

    public init(
        defaultTemperature: Float = 0.7,
        maxTokensPerRequest: Int = 2048,
        onDeviceOnly: Bool = true
    ) {
        self.defaultTemperature = max(0.0, min(1.0, defaultTemperature))
        self.maxTokensPerRequest = max(1, maxTokensPerRequest)
        self.onDeviceOnly = onDeviceOnly
    }

    // MARK: - Presets

    /// Default configuration
    public static let `default` = FoundationModelsConfiguration()

    /// Configuration optimized for privacy (on-device only)
    public static let privacy = FoundationModelsConfiguration(
        onDeviceOnly: true
    )

    /// Configuration optimized for performance (allow cloud fallback)
    public static let performance = FoundationModelsConfiguration(
        maxTokensPerRequest: 4096,
        onDeviceOnly: false
    )
}
