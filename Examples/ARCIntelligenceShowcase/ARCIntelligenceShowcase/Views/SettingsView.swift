//
//  SettingsView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var isCheckingAvailability = false
    @State private var availabilityStatus = ""

    var body: some View {
        @Bindable var appState = appState
        List {
            Section {
                ForEach(ProviderType.allCases, id: \.self) { providerType in
                    Button {
                        appState.updateProvider(to: providerType)
                    } label: {
                        HStack {
                            Image(systemName: providerType.icon)
                                .frame(width: 30)
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(providerType.rawValue)
                                    .foregroundColor(.primary)

                                Text(providerType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if appState.selectedProvider == providerType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Select which AI provider to use for examples. Mock provider is recommended for demo purposes.")
            }

            if appState.selectedProvider == .anthropic {
                Section {
                    SecureField("API Key (sk-ant-...)", text: $appState.anthropicAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .onChange(of: appState.anthropicAPIKey) {
                            appState.updateProvider(to: .anthropic)
                        }

                    Picker("Model", selection: $appState.anthropicModel) {
                        Text("Haiku (Fast)").tag(AnthropicModel.haiku)
                        Text("Sonnet (Balanced)").tag(AnthropicModel.sonnet)
                        Text("Opus (Quality)").tag(AnthropicModel.opus)
                    }
                    .onChange(of: appState.anthropicModel) {
                        appState.updateProvider(to: .anthropic)
                    }
                } header: {
                    Text("Anthropic Settings")
                } footer: {
                    Text("Enter your Anthropic API key. Do not use in production apps — use AIProxy instead.")
                }
            }

            if appState.selectedProvider == .openAI {
                Section {
                    SecureField("API Key (sk-...)", text: $appState.openAIAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .onChange(of: appState.openAIAPIKey) {
                            appState.updateProvider(to: .openAI)
                        }

                    Picker("Model", selection: $appState.openAIModel) {
                        Text("GPT-4o Mini (Fast)").tag(OpenAIModel.gpt4oMini)
                        Text("GPT-4o (Balanced)").tag(OpenAIModel.gpt4o)
                        Text("o3-mini (Reasoning)").tag(OpenAIModel.o3Mini)
                    }
                    .onChange(of: appState.openAIModel) {
                        appState.updateProvider(to: .openAI)
                    }
                } header: {
                    Text("OpenAI Settings")
                } footer: {
                    Text("Enter your OpenAI API key. Do not use in production apps — use AIProxy instead.")
                }
            }

            if appState.selectedProvider == .grok {
                Section {
                    SecureField("API Key (xai-...)", text: $appState.grokAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .onChange(of: appState.grokAPIKey) {
                            appState.updateProvider(to: .grok)
                        }

                    Picker("Model", selection: $appState.grokModel) {
                        Text("Grok 3 Fast").tag(GrokModel.grok3Fast)
                        Text("Grok 3").tag(GrokModel.grok3)
                    }
                    .onChange(of: appState.grokModel) {
                        appState.updateProvider(to: .grok)
                    }
                } header: {
                    Text("Grok (xAI) Settings")
                } footer: {
                    Text("Enter your xAI API key. Do not use in production apps — use AIProxy instead.")
                }
            }

            Section {
                Button {
                    Task {
                        await checkAvailability()
                    }
                } label: {
                    HStack {
                        Text("Check Availability")

                        Spacer()

                        if isCheckingAvailability {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                .disabled(isCheckingAvailability)

                if !availabilityStatus.isEmpty {
                    Text(availabilityStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Provider Status")
            }

            Section {
                HStack {
                    Text("Provider ID")
                    Spacer()
                    Text(appState.currentProvider.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Display Name")
                    Spacer()
                    Text(appState.currentProvider.displayName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Version")
                    Spacer()
                    Text(appState.currentProvider.version)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Current Provider Info")
            }

            Section {
                if let githubURL = URL(string: "https://github.com/arclabs-studio/ARCIntelligence") {
                    Link(destination: githubURL) {
                        HStack {
                            Image(systemName: "link")
                            Text("View on GitHub")
                        }
                    }
                }

                if let websiteURL = URL(string: "https://arclabs.studio") {
                    Link(destination: websiteURL) {
                        HStack {
                            Image(systemName: "globe")
                            Text("ARC Labs Studio Website")
                        }
                    }
                }
            } header: {
                Text("Resources")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkAvailability() async {
        isCheckingAvailability = true
        availabilityStatus = ""

        let isAvailable = await appState.currentProvider.isAvailable()

        availabilityStatus = isAvailable
            ? "✅ Provider is available and ready"
            : "❌ Provider is not available on this device"

        isCheckingAvailability = false
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environment(AppState())
    }
}
