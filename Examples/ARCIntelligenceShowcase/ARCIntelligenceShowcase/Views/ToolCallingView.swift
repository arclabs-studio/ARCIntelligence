//
//  ToolCallingView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 21/03/2026.
//

import ARCIntelligence
import SwiftUI

// MARK: - Demo Tools

private struct WordCountTool: IntelligenceTool {
    let name = "countWords"
    let description = "Count the number of words in a text string"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(parameters: [ToolParameter(name: "text", type: .string,
                                                        description: "The text to count words in")],
                             required: ["text"])
    }

    func execute(arguments: [String: ToolArgumentValue]) async throws -> String {
        let text = arguments["text"]?.stringValue ?? ""
        let count = text.split(separator: " ").count
        return "\(count) word\(count == 1 ? "" : "s")"
    }
}

private struct CurrentDateTool: IntelligenceTool {
    let name = "getCurrentDate"
    let description = "Get the current date and time"

    func execute(arguments _: [String: ToolArgumentValue]) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

private struct TemperatureConverterTool: IntelligenceTool {
    let name = "convertTemperature"
    let description = "Convert temperature between Celsius and Fahrenheit"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(parameters: [ToolParameter(name: "value", type: .number,
                                                        description: "The temperature value to convert"),
                                          ToolParameter(name: "from",
                                                        type: .string,
                                                        description: "The source unit: 'celsius' or 'fahrenheit'",
                                                        enumValues: ["celsius", "fahrenheit"])],
                             required: ["value", "from"])
    }

    func execute(arguments: [String: ToolArgumentValue]) async throws -> String {
        guard let value = arguments["value"]?.doubleValue,
              let from = arguments["from"]?.stringValue
        else {
            throw IntelligenceError.invalidRequest("Missing required arguments")
        }

        switch from.lowercased() {
        case "celsius":
            let fahrenheit = value * 9 / 5 + 32
            return String(format: "%.1f°C = %.1f°F", value, fahrenheit)
        case "fahrenheit":
            let celsius = (value - 32) * 5 / 9
            return String(format: "%.1f°F = %.1f°C", value, celsius)
        default:
            throw IntelligenceError.invalidRequest("Unknown unit: \(from)")
        }
    }
}

// MARK: - View

struct ToolCallingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ToolCallingViewModel()

    private static let demoTools: [any IntelligenceTool] = [WordCountTool(),
                                                            CurrentDateTool(),
                                                            TemperatureConverterTool()]

    var body: some View {
        VStack(spacing: 0) {
            if appState.toolProvider == nil {
                UnavailableFeatureView(message: "Tool calling requires Foundation Models, Anthropic, OpenAI, or Grok. Switch provider in Settings.")
            } else {
                toolsInfoBanner
                    .padding()

                Divider()

                resultsArea

                Divider()

                inputArea
            }
        }
        .navigationTitle("Tool Calling")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var toolsInfoBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Available Tools")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ToolBadge(name: "countWords", icon: "number")
                ToolBadge(name: "getCurrentDate", icon: "calendar")
                ToolBadge(name: "convertTemperature", icon: "thermometer")
            }
        }
    }

    private var resultsArea: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.turns.isEmpty {
                    Text("Ask something that uses one of the tools above.\nTry: \"How many words are in 'Hello World'?\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                }

                ForEach(viewModel.turns) { turn in
                    TurnView(turn: turn)
                }

                if viewModel.isResponding {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Working...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask something...", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isResponding)

            Button {
                Task {
                    if let provider = appState.toolProvider {
                        await viewModel.send(provider: provider, tools: Self.demoTools)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.inputText.isEmpty ? .gray : .accentColor)
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isResponding)
        }
        .padding()
    }
}

// MARK: - Turn View

private struct TurnView: View {
    let turn: ToolCallingTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User prompt
            HStack {
                Spacer()
                Text(turn.prompt)
                    .padding(12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .trailing)
            }

            // Tool calls (if any)
            if !turn.toolCalls.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tool Calls")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    ForEach(turn.toolCalls, id: \.toolName) { call in
                        ToolCallCard(call: call)
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1))
                .cornerRadius(10)
            }

            // AI response
            HStack {
                Text(turn.response)
                    .padding(12)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .leading)
                Spacer()
            }
        }
    }
}

// MARK: - Tool Call Card

private struct ToolCallCard: View {
    let call: ToolCallRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(call.toolName)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0fms", call.duration * 1000))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !call.arguments.isEmpty {
                Text("Args: " + call.arguments.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("→ " + call.output)
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Tool Badge

private struct ToolBadge: View {
    let name: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(name)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
}

// MARK: - Model

struct ToolCallingTurn: Identifiable {
    let id = UUID()
    let prompt: String
    let toolCalls: [ToolCallRecord]
    let response: String
}

// MARK: - View Model

@MainActor
@Observable final class ToolCallingViewModel {
    var inputText = ""
    var isResponding = false
    var turns: [ToolCallingTurn] = []

    func send(provider: any ToolProvider, tools: [any IntelligenceTool]) async {
        let prompt = inputText
        inputText = ""
        isResponding = true

        do {
            let (response, toolCalls) = try await provider.respondWithToolCalls(to: prompt,
                                                                                tools: tools,
                                                                                configuration: .default)

            turns.append(ToolCallingTurn(prompt: prompt,
                                         toolCalls: toolCalls,
                                         response: response.content))
        } catch {
            turns.append(ToolCallingTurn(prompt: prompt,
                                         toolCalls: [],
                                         response: "Error: \(error.localizedDescription)"))
        }

        isResponding = false
    }
}

#Preview {
    NavigationView {
        ToolCallingView()
            .environment(AppState())
    }
}
