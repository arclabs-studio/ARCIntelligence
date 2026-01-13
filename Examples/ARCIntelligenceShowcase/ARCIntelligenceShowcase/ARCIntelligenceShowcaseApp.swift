//
//  ARCIntelligenceShowcaseApp.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI
import ARCIntelligence
import ARCIntelligenceMocks

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

    init() {
        self.currentProvider = MockIntelligenceProvider(
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
        }
    }

    var conversationProvider: ConversationProvider {
        currentProvider as? ConversationProvider ?? MockIntelligenceProvider()
    }
}

enum ProviderType: String, CaseIterable {
    case mock = "Mock (Demo)"
    case foundationModels = "Foundation Models (iOS 18+)"

    var description: String {
        switch self {
        case .mock:
            return "Mock provider for testing and demo purposes"
        case .foundationModels:
            return "Apple's on-device AI (requires iOS 18.0+)"
        }
    }

    var icon: String {
        switch self {
        case .mock:
            return "theatermasks.fill"
        case .foundationModels:
            return "apple.logo"
        }
    }
}
