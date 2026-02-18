//
//  ConversationView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import ARCIntelligence
import SwiftUI

struct ConversationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ConversationViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isThinking {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isThinking)

                Button {
                    Task {
                        await viewModel.sendMessage(provider: appState.conversationProvider)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.inputText.isEmpty ? .gray : .accentColor)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isThinking)
            }
            .padding()
        }
        .navigationTitle("Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.clearConversation()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.messages.isEmpty)
            }
        }
        .task {
            await viewModel.startConversation(provider: appState.conversationProvider)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var inputText = ""
    var isThinking = false

    private var assistant: ConversationalAssistant?

    func startConversation(provider: ConversationProvider) async {
        assistant = ConversationalAssistant(provider: provider)
        _ = await assistant?.startConversation(systemPrompt: "You are a helpful AI assistant. Be concise and friendly.")
    }

    func sendMessage(provider _: ConversationProvider) async {
        guard !inputText.isEmpty else { return }

        let userMessageContent = inputText
        inputText = ""

        // Add user message
        let userMessage = Message(role: .user,
                                  content: userMessageContent)
        messages.append(userMessage)

        // Get AI response
        isThinking = true

        do {
            let responseText = try await assistant?.sendMessage(userMessageContent) ?? "Error: No assistant"

            let assistantMessage = Message(role: .assistant,
                                           content: responseText)
            messages.append(assistantMessage)

        } catch {
            let errorMessage = Message(role: .assistant,
                                       content: "Error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }

        isThinking = false
    }

    func clearConversation() {
        messages.removeAll()
        Task { [weak self] in
            await self?.assistant?.endConversation()
        }
    }
}

#Preview {
    NavigationView {
        ConversationView()
            .environment(AppState())
    }
}
