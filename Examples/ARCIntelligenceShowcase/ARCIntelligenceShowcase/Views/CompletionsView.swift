//
//  CompletionsView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI
import ARCIntelligence

struct CompletionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CompletionsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.headline)

                    TextEditor(text: $viewModel.prompt)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding()

                // Configuration Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration")
                        .font(.headline)

                    Picker("Preset", selection: $viewModel.selectedPreset) {
                        Text("Default").tag(ConfigPreset.default)
                        Text("Factual").tag(ConfigPreset.factual)
                        Text("Creative").tag(ConfigPreset.creative)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Temperature:")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.temperature))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Generate Button
                Button {
                    Task {
                        await viewModel.generate(provider: appState.currentProvider)
                    }
                } label: {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "sparkles")
                        }

                        Text(viewModel.isGenerating ? "Generating..." : "Generate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isGenerating || viewModel.prompt.isEmpty)
                .padding(.horizontal)

                // Response Section
                if !viewModel.response.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Response")
                                .font(.headline)

                            Spacer()

                            if let tokens = viewModel.tokensUsed {
                                Text("\(tokens) tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text(viewModel.response)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .transition(.opacity)
                }

                // Error Section
                if let error = viewModel.error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
        }
        .navigationTitle("Text Completions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Model

@MainActor
class CompletionsViewModel: ObservableObject {
    @Published var prompt = "Explain quantum computing in simple terms"
    @Published var selectedPreset: ConfigPreset = .default
    @Published var temperature: Double = 0.7
    @Published var response = ""
    @Published var tokensUsed: Int?
    @Published var isGenerating = false
    @Published var error: String?

    func generate(provider: IntelligenceProvider) async {
        isGenerating = true
        error = nil
        response = ""
        tokensUsed = nil

        do {
            let config = CompletionConfiguration(
                temperature: Float(temperature),
                maxTokens: 1024
            )

            let result = try await provider.complete(
                prompt: prompt,
                configuration: config
            )

            response = result.content
            tokensUsed = result.tokensUsed

        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }
}

enum ConfigPreset {
    case `default`, factual, creative

    var temperature: Double {
        switch self {
        case .default: return 0.7
        case .factual: return 0.3
        case .creative: return 0.9
        }
    }
}

#Preview {
    NavigationView {
        CompletionsView()
            .environmentObject(AppState())
    }
}
