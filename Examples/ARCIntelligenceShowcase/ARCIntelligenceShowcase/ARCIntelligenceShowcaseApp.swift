//
//  ARCIntelligenceShowcaseApp.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import ARCIntelligenceMocks
import SwiftUI

@main
struct ARCIntelligenceShowcaseApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var selectedProvider: ProviderType = .mock
    @Published var currentProvider: IntelligenceProvider

    // Anthropic settings
    @Published var anthropicAPIKey: String = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    @Published var anthropicModel: AnthropicModel = .sonnet

    init() {
        currentProvider = MockIntelligenceProvider(
            responses: ["This is a mock response. Switch to Foundation Models in Settings for real AI."]
        )
    }

    func updateProvider(to type: ProviderType) {
        selectedProvider = type

        switch type {
        case .mock:
            currentProvider = MockIntelligenceProvider(
                responses: [
                    "This is a mock response from ARCIntelligence.",
                    "Mock providers are great for testing and development!",
                    "Switch to Foundation Models for real AI capabilities."
                ]
            )

        case .foundationModels:
            currentProvider = ARCIntelligence.foundationModels()

        case .anthropic:
            UserDefaults.standard.set(anthropicAPIKey, forKey: "anthropic_api_key")
            let config = AnthropicConfiguration(
                authentication: .apiKey(anthropicAPIKey),
                model: anthropicModel
            )
            currentProvider = ARCIntelligence.anthropic(configuration: config)
        }
    }

    var conversationProvider: ConversationProvider {
        currentProvider as? ConversationProvider ?? MockIntelligenceProvider()
    }
}

enum ProviderType: String, CaseIterable {
    case mock = "Mock (Demo)"
    case foundationModels = "Foundation Models (iOS 18+)"
    case anthropic = "Anthropic Claude"

    var description: String {
        switch self {
        case .mock:
            "Mock provider for testing and demo purposes"
        case .foundationModels:
            "Apple's on-device AI (requires iOS 18.0+)"
        case .anthropic:
            "Claude API (Haiku/Sonnet/Opus) — requires API key"
        }
    }

    var icon: String {
        switch self {
        case .mock:
            "theatermasks.fill"
        case .foundationModels:
            "apple.logo"
        case .anthropic:
            "cloud.fill"
        }
    }
}
