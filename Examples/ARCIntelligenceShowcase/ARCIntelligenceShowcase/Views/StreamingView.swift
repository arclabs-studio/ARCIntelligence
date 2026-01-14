//
//  StreamingView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI
import ARCIntelligence

struct StreamingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = StreamingViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.headline)

                    TextEditor(text: $viewModel.prompt)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding()

                // Stream Button
                Button {
                    Task {
                        await viewModel.startStreaming(provider: appState.currentProvider)
                    }
                } label: {
                    HStack {
                        if viewModel.isStreaming {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "play.fill")
                        }

                        Text(viewModel.isStreaming ? "Streaming..." : "Start Streaming")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isStreaming ? Color.orange : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.prompt.isEmpty)
                .padding(.horizontal)

                // Stop Button
                if viewModel.isStreaming {
                    Button {
                        viewModel.stopStreaming()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                // Response Section
                if !viewModel.streamedResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Streaming Response")
                                .font(.headline)

                            Spacer()

                            Text("\(viewModel.streamedResponse.count) chars")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ScrollView {
                            Text(viewModel.streamedResponse)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
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
                }
            }
        }
        .navigationTitle("Streaming")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Model

@MainActor
class StreamingViewModel: ObservableObject {
    @Published var prompt = "Write a short story about AI and humans working together"
    @Published var streamedResponse = ""
    @Published var isStreaming = false
    @Published var error: String?

    private var streamTask: Task<Void, Never>?

    func startStreaming(provider: IntelligenceProvider) async {
        isStreaming = true
        error = nil
        streamedResponse = ""

        streamTask = Task {
            do {
                let stream = provider.streamComplete(
                    prompt: prompt,
                    configuration: .creative
                )

                for try await chunk in stream {
                    if Task.isCancelled { break }
                    streamedResponse += chunk
                }

            } catch {
                self.error = error.localizedDescription
            }

            isStreaming = false
        }

        await streamTask?.value
    }

    func stopStreaming() {
        streamTask?.cancel()
        isStreaming = false
    }
}

#Preview {
    NavigationView {
        StreamingView()
            .environmentObject(AppState())
    }
}
