//
//  ContentView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationView {
            List {
                Section("Examples") {
                    NavigationLink {
                        CompletionsView()
                    } label: {
                        ExampleRow(
                            icon: "doc.text.fill",
                            title: "Text Completions",
                            description: "Generate AI completions"
                        )
                    }

                    NavigationLink {
                        StreamingView()
                    } label: {
                        ExampleRow(
                            icon: "wave.3.right",
                            title: "Streaming Responses",
                            description: "Real-time token streaming"
                        )
                    }

                    NavigationLink {
                        ConversationView()
                    } label: {
                        ExampleRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Conversations",
                            description: "Multi-turn dialogues"
                        )
                    }

                    NavigationLink {
                        UtilitiesView()
                    } label: {
                        ExampleRow(
                            icon: "wrench.and.screwdriver.fill",
                            title: "Utilities",
                            description: "Prompt builder & token counter"
                        )
                    }
                }

                Section("Configuration") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        ExampleRow(
                            icon: "gearshape.fill",
                            title: "Settings",
                            description: "Configure AI provider"
                        )
                    }
                }

                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        ExampleRow(
                            icon: "info.circle.fill",
                            title: "About ARCIntelligence",
                            description: "Learn more about the package"
                        )
                    }
                }
            }
            .navigationTitle("ARCIntelligence")
        }
    }
}

// MARK: - Example Row

struct ExampleRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
