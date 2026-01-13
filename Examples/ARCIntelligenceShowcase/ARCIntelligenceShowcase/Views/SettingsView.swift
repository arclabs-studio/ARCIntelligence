//
//  SettingsView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI
import ARCIntelligence

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCheckingAvailability = false
    @State private var availabilityStatus = ""

    var body: some View {
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
                Link(destination: URL(string: "https://github.com/arclabs-studio/ARCIntelligence")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                }

                Link(destination: URL(string: "https://arclabs.studio")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("ARC Labs Studio Website")
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
            .environmentObject(AppState())
    }
}
