# Getting Started with ARCIntelligence

Learn how to integrate AI capabilities into your iOS and macOS applications.

## Overview

ARCIntelligence provides a unified interface for AI-powered features. This guide walks you through the basic setup and common use cases.

## Installation

Add ARCIntelligence to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCIntelligence", from: "1.0.0")
]
```

## Basic Usage

### Creating a Provider

```swift
import ARCIntelligence

// Create the Foundation Models provider (on-device AI)
let provider = ARCIntelligence.foundationModels()

// Check availability
guard await provider.isAvailable() else {
    print("Foundation Models not available on this device")
    return
}
```

### Text Completion

Generate AI completions for prompts:

```swift
let response = try await provider.complete(
    prompt: "Explain quantum computing in simple terms",
    configuration: .factual
)

print(response.content)
```

### Streaming Responses

For real-time streaming of AI responses:

```swift
for try await chunk in provider.streamComplete(
    prompt: "Write a short story about AI",
    configuration: .creative
) {
    print(chunk, terminator: "")
}
```

### Multi-turn Conversations

Use the ``ConversationalAssistant`` for dialogue management:

```swift
let assistant = ARCIntelligence.conversationalAssistant(provider: provider)

// Start a conversation
_ = await assistant.startConversation(
    systemPrompt: "You are a helpful coding assistant"
)

// Send messages
let response = try await assistant.sendMessage("What is SwiftUI?")
print(response)

// End the conversation
await assistant.endConversation()
```

## Configuration Presets

ARCIntelligence provides preset configurations for common use cases:

| Preset | Temperature | Use Case |
|--------|-------------|----------|
| `.default` | 0.7 | General purpose |
| `.factual` | 0.2 | Accurate, deterministic responses |
| `.creative` | 0.9 | Creative, varied responses |

## Testing with Mocks

Import `ARCIntelligenceMocks` to use mock providers in your tests:

```swift
import Testing
import ARCIntelligence
import ARCIntelligenceMocks

@Test func myAIFeature() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["Expected response"]
    )

    let assistant = ConversationalAssistant(provider: mockProvider)
    // ... test your feature
}
```

## Next Steps

- Explore the ``SemanticSearch`` use case for embedding-based search
- Learn about ``RecommendationEngine`` for personalized suggestions
- Check the example app in `Examples/ARCIntelligenceShowcase/`
