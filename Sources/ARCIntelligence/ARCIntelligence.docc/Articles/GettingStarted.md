# Getting Started with ARCIntelligence

Learn how to integrate ARCIntelligence into your iOS or macOS application.

## Overview

This guide will walk you through the basics of integrating ARCIntelligence into your project, from installation to making your first AI request.

## Installation

### Swift Package Manager

Add ARCIntelligence to your project using Xcode:

1. Open your project in Xcode
2. Navigate to **File → Add Package Dependencies**
3. Enter the repository URL: `https://github.com/arclabs-studio/ARCIntelligence.git`
4. Select the version or branch you want to use
5. Add the package to your target

Alternatively, add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCIntelligence.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["ARCIntelligence"]
)
```

## Requirements

- **Swift:** 6.0+
- **Platforms:** iOS 17.0+ / macOS 14.0+
- **Foundation Models:** iOS 26+ (for on-device AI features)
- **Xcode:** 16.0+

## Your First Completion

Here's how to generate your first AI completion using Foundation Models:

```swift
import ARCIntelligence

// Create a provider
let provider = ARCIntelligence.foundationModels()

// Check if the provider is available on this device
guard await provider.isAvailable() else {
    print("Foundation Models not available on this device")
    return
}

// Generate a completion
do {
    let response = try await provider.complete(
        prompt: "Explain quantum computing in simple terms",
        configuration: .factual
    )

    print(response.content)
    print("Tokens used: \(response.tokensUsed)")
} catch {
    print("Error: \(error)")
}
```

## Starting a Conversation

To maintain context across multiple messages, use the ``ConversationalAssistant``:

```swift
import ARCIntelligence

// Create provider and assistant
let provider = ARCIntelligence.foundationModels()
let assistant = ARCIntelligence.conversationalAssistant(provider: provider)

// Start a new conversation with a system prompt
let conversation = await assistant.startConversation(
    systemPrompt: "You are a helpful coding assistant specializing in Swift"
)

// Send messages
do {
    let response1 = try await assistant.sendMessage("What is SwiftUI?")
    print("Assistant: \(response1)")

    let response2 = try await assistant.sendMessage("Show me a simple example")
    print("Assistant: \(response2)")

    // Get the full conversation history
    let history = try await assistant.conversationHistory()
    print("Total messages in conversation: \(history.count)")
} catch {
    print("Error: \(error)")
}

// Clean up when done
await assistant.endConversation()
```

## Streaming Responses

For real-time feedback, use streaming completions:

```swift
import ARCIntelligence

let provider = ARCIntelligence.foundationModels()

print("Streaming response: ", terminator: "")

do {
    for try await chunk in provider.streamComplete(
        prompt: "Write a short story about artificial intelligence",
        configuration: .creative
    ) {
        print(chunk, terminator: "")
    }
    print() // New line at the end
} catch {
    print("\nError: \(error)")
}
```

## Configuration Options

ARCIntelligence provides several preset configurations:

### Factual Configuration
Best for accurate, deterministic responses:

```swift
let response = try await provider.complete(
    prompt: "What is the capital of France?",
    configuration: .factual  // Low temperature (0.3)
)
```

### Creative Configuration
Best for creative writing and brainstorming:

```swift
let response = try await provider.complete(
    prompt: "Write a poem about coding",
    configuration: .creative  // High temperature (0.9)
)
```

### Custom Configuration
For fine-grained control:

```swift
let customConfig = CompletionConfiguration(
    temperature: 0.7,
    maxTokens: 500,
    systemPrompt: "You are a helpful assistant",
    stopSequences: ["END"],
    topP: 0.95
)

let response = try await provider.complete(
    prompt: "Your prompt here",
    configuration: customConfig
)
```

## Error Handling

Always handle potential errors when working with AI providers:

```swift
do {
    let response = try await provider.complete(
        prompt: "Your prompt",
        configuration: .default
    )
    // Handle response
} catch IntelligenceError.providerUnavailable {
    print("AI provider is not available on this device")
} catch IntelligenceError.tokenLimitExceeded(let current, let max) {
    print("Token limit exceeded: \(current)/\(max)")
} catch IntelligenceError.requestFailed(let reason) {
    print("Request failed: \(reason)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Next Steps

Now that you understand the basics, explore these topics:

- <doc:Architecture> - Learn about the package architecture
- <doc:ChoosingAProvider> - Understand different AI providers
- <doc:GuidedGeneration> - Generate structured Swift types
- <doc:ToolCalling> - Extend model capabilities with tools
- <doc:ContentTagging> - Extract tags from text content
- <doc:Testing> - Test your AI features with mocks
- <doc:BestPractices> - Follow best practices for AI integration

## See Also

- ``IntelligenceProvider``
- ``ConversationProvider``
- ``ConversationalAssistant``
- ``CompletionConfiguration``
