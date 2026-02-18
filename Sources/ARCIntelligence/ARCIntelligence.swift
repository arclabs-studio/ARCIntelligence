//
//  ARCIntelligence.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCLogger
import Foundation

/// Main public API for ARCIntelligence package.
///
/// ARCIntelligence provides AI capabilities for iOS and macOS apps through
/// a clean, protocol-based architecture that abstracts different AI providers.
///
/// ## Topics
///
/// ### Core Protocols
/// - ``IntelligenceProvider``
/// - ``ConversationProvider``
/// - ``RecommendationProvider``
/// - ``EmbeddingProvider``
/// - ``GenerableProvider``
/// - ``ToolProvider``
/// - ``ContentTaggingProvider``
///
/// ### Providers
/// - ``FoundationModelsProvider``
/// - ``FoundationModelsConfiguration``
/// - ``AnthropicProvider``
/// - ``AnthropicConfiguration``
/// - ``AnthropicModel``
/// - ``AnthropicAuthentication``
/// - ``OpenAIProvider``
/// - ``OpenAIConfiguration``
/// - ``OpenAIModel``
/// - ``OpenAIAuthentication``
/// - ``GrokProvider``
/// - ``GrokConfiguration``
/// - ``GrokModel``
/// - ``GrokAuthentication``
///
/// ### Use Cases
/// - ``ConversationalAssistant``
/// - ``RecommendationEngine``
/// - ``SemanticSearch``
///
/// ### Models
/// - ``Message``
/// - ``Conversation``
/// - ``Recommendation``
/// - ``Embedding``
/// - ``IntelligenceResponse``
/// - ``CompletionConfiguration``
/// - ``ContentTag``
/// - ``TagCategory``
/// - ``ToolCallRecord``
/// - ``IntelligenceTool``
/// - ``SessionTranscript``
/// - ``TranscriptEntry``
///
/// ### Utilities
/// - ``PromptBuilder``
/// - ``TokenCounter``
///
/// ### Errors
/// - ``IntelligenceError``
public enum ARCIntelligence {
    // MARK: - Version

    /// Current version of ARCIntelligence
    public static let version = "1.0.0"

    // MARK: - Logging

    /// Shared logger for the ARCIntelligence package.
    static let logger = ARCLogger(subsystem: "com.arclabs.intelligence",
                                  category: "ARCIntelligence")
}
