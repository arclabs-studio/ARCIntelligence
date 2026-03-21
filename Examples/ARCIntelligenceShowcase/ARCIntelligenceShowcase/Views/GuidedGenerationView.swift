//
//  GuidedGenerationView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 21/03/2026.
//

import ARCIntelligence
import SwiftUI

// MARK: - Demo Type

struct BookSummary: Codable, Sendable {
    let title: String
    let genre: String
    let synopsis: String
    let recommendedAge: String
}

// MARK: - View

struct GuidedGenerationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = GuidedGenerationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if appState.generableProvider == nil {
                    UnavailableFeatureView(message: "Guided generation requires Foundation Models, Anthropic, OpenAI, or Grok. Switch provider in Settings.")
                } else {
                    inputSection
                    generateButton
                    if let result = viewModel.result {
                        resultSection(result)
                            .transition(.opacity)
                    }
                    if let error = viewModel.error {
                        ErrorView(message: error)
                            .transition(.opacity)
                    }
                }
            }
        }
        .navigationTitle("Guided Generation")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: viewModel.result != nil)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Book Title")
                .font(.headline)

            TextField("e.g. The Lord of the Rings", text: $viewModel.prompt)
                .textFieldStyle(.roundedBorder)

            Text("The AI returns a structured `BookSummary` object — no manual JSON parsing needed.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var generateButton: some View {
        Button {
            Task {
                if let provider = appState.generableProvider {
                    await viewModel.generate(provider: provider)
                }
            }
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(viewModel.isGenerating ? "Generating..." : "Generate Structured Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.isGenerating || viewModel.prompt.isEmpty)
        .padding(.horizontal)
    }

    private func resultSection(_ result: BookSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Structured Result")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                FieldRow(label: "Title", value: result.title)
                FieldRow(label: "Genre", value: result.genre)
                FieldRow(label: "Recommended Age", value: result.recommendedAge)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Synopsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(result.synopsis)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Subviews

private struct FieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .frame(width: 130, alignment: .leading)

            Text(value)
        }
    }
}

// MARK: - View Model

@MainActor
@Observable final class GuidedGenerationViewModel {
    var prompt = "The Lord of the Rings"
    var isGenerating = false
    var result: BookSummary?
    var error: String?

    func generate(provider: any GenerableProvider) async {
        isGenerating = true
        error = nil
        result = nil

        do {
            result = try await provider.generate(BookSummary.self,
                                                 prompt: "Describe the book '\(prompt)'. Fill in all fields.",
                                                 schemaDescription: "A book summary with title, genre, a 2-sentence synopsis, and recommended age range",
                                                 configuration: .factual)
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }
}

#Preview {
    NavigationView {
        GuidedGenerationView()
            .environment(AppState())
    }
}
