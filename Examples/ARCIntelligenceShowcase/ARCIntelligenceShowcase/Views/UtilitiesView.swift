//
//  UtilitiesView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import SwiftUI

struct UtilitiesView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            Picker("Utility", selection: $selectedTab) {
                Text("Prompt Builder").tag(0)
                Text("Token Counter").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            TabView(selection: $selectedTab) {
                PromptBuilderDemo()
                    .tag(0)

                TokenCounterDemo()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Utilities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Prompt Builder Demo

struct PromptBuilderDemo: View {
    @State private var systemInstruction = "You are a helpful assistant"
    @State private var context = "User is learning Swift programming"
    @State private var query = "Explain optionals"
    @State private var builtPrompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Prompt Builder")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("System Instruction")
                        .font(.headline)

                    TextEditor(text: $systemInstruction)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Context")
                        .font(.headline)

                    TextEditor(text: $context)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Query")
                        .font(.headline)

                    TextField("Enter query", text: $query)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                Button {
                    buildPrompt()
                } label: {
                    Text("Build Prompt")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if !builtPrompt.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Built Prompt")
                            .font(.headline)

                        Text(builtPrompt)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func buildPrompt() {
        builtPrompt = PromptBuilder()
            .withSystemInstruction(systemInstruction)
            .withContext(context)
            .withQuery(query)
            .build()
    }
}

// MARK: - Token Counter Demo

struct TokenCounterDemo: View {
    @State private var text = "This is a sample text to count tokens"
    @State private var estimatedTokens = 0
    @State private var tokenLimit = 100
    @State private var fitsWithinLimit = false
    @State private var truncatedText = ""

    private let counter = TokenCounter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Token Counter")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Text")
                        .font(.headline)

                    TextEditor(text: $text)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: text) {
                            updateTokenCount()
                        }
                }
                .padding(.horizontal)

                Button {
                    updateTokenCount()
                } label: {
                    Text("Count Tokens")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    InfoRow(
                        label: "Estimated Tokens",
                        value: "\(estimatedTokens)"
                    )

                    InfoRow(
                        label: "Character Count",
                        value: "\(text.count)"
                    )

                    InfoRow(
                        label: "Word Count",
                        value: "\(text.split(separator: " ").count)"
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Token Limit Check")
                        .font(.headline)

                    HStack {
                        Text("Limit:")
                        Spacer()
                        Text("\(tokenLimit) tokens")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(tokenLimit) },
                        set: { tokenLimit = Int($0) }
                    ), in: 10 ... 500, step: 10)

                    HStack {
                        Text("Fits within limit:")
                        Spacer()
                        Image(systemName: fitsWithinLimit ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(fitsWithinLimit ? .green : .red)
                    }
                }
                .padding(.horizontal)

                if !fitsWithinLimit, !truncatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Truncated Text")
                            .font(.headline)

                        Text(truncatedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func updateTokenCount() {
        estimatedTokens = counter.estimateTokens(for: text)
        fitsWithinLimit = counter.fitsWithinLimit(text, limit: tokenLimit)

        if !fitsWithinLimit {
            truncatedText = counter.truncate(text, toLimit: tokenLimit)
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        UtilitiesView()
    }
}
