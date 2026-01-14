# Architecture Overview

Understand the design principles and structure of ARCIntelligence.

## Overview

ARCIntelligence is built on a clean, protocol-based architecture that separates concerns and makes it easy to swap AI providers without changing your application code.

## Design Principles

### Protocol-Oriented Design

The package is built around four core protocols that define capabilities:

1. **``IntelligenceProvider``** - Base protocol for all AI providers
2. **``ConversationProvider``** - Multi-turn conversations with context
3. **``RecommendationProvider``** - Context-based recommendations
4. **``EmbeddingProvider``** - Vector embeddings for semantic search

### Provider Independence

Your application code depends on protocols, not concrete implementations. This allows you to:

- Switch between providers without code changes
- Test with mocks instead of real API calls
- Support multiple providers in the same app
- Add custom providers easily

```swift
// Your code depends on the protocol
func generateSuggestion(provider: IntelligenceProvider) async throws -> String {
    let response = try await provider.complete(
        prompt: "Suggest a feature",
        configuration: .default
    )
    return response.content
}

// Works with any provider implementation
let foundationProvider = ARCIntelligence.foundationModels()
let suggestion1 = try await generateSuggestion(provider: foundationProvider)

let mockProvider = MockIntelligenceProvider()
let suggestion2 = try await generateSuggestion(provider: mockProvider)
```

### Swift 6 Concurrency

All components are fully `Sendable` and use Swift's modern concurrency features:

- `async/await` for asynchronous operations
- `AsyncThrowingStream` for streaming responses
- `actor` for thread-safe state management
- Strict concurrency checking enabled

## Architecture Layers

### Layer 1: Core Protocols

The foundation of the package, defining capabilities:

```
Core/Protocols/
├── IntelligenceProvider.swift    - Base AI provider
├── ConversationProvider.swift    - Conversation support
├── RecommendationProvider.swift  - Recommendations
└── EmbeddingProvider.swift       - Semantic embeddings
```

### Layer 2: Models

Value types representing data:

```
Core/Models/
├── Message.swift                     - Single conversation message
├── Conversation.swift                - Multi-turn conversation
├── Recommendation.swift              - Single recommendation
├── Embedding.swift                   - Vector representation
├── IntelligenceResponse.swift        - Provider response
├── IntelligenceRequest.swift         - Provider request
├── CompletionConfiguration.swift     - Completion settings
└── RecommendationConfiguration.swift - Recommendation settings
```

### Layer 3: Providers

Concrete implementations of protocols:

```
Providers/
├── FoundationModels/
│   ├── FoundationModelsProvider.swift      - Apple AI implementation
│   ├── FoundationModelsConfiguration.swift - Provider configuration
│   └── FoundationModelsCapabilities.swift  - Capability detection
└── Mock/
    ├── MockIntelligenceProvider.swift      - Testing mock
    └── MockConversationProvider.swift      - Conversation mock
```

### Layer 4: Use Cases

High-level business logic:

```
UseCases/
├── ConversationalAssistant.swift  - Conversation management
├── RecommendationEngine.swift     - Recommendation generation
└── SemanticSearch.swift           - Vector-based search
```

### Layer 5: Utilities

Helper classes:

```
Utilities/
├── PromptBuilder.swift  - Construct formatted prompts
└── TokenCounter.swift   - Estimate token usage
```

## Data Flow

### Simple Completion Flow

```
Application
    ↓
IntelligenceProvider (protocol)
    ↓
FoundationModelsProvider (implementation)
    ↓
Apple Foundation Models API
    ↓
IntelligenceResponse
    ↓
Application
```

### Conversation Flow

```
Application
    ↓
ConversationalAssistant (use case)
    ↓
ConversationProvider (protocol)
    ↓
FoundationModelsProvider (implementation)
    ↓
Apple Foundation Models API
    ↓
Message
    ↓
ConversationalAssistant (updates state)
    ↓
Application
```

## Component Relationships

### Provider Hierarchy

```swift
protocol IntelligenceProvider {
    // Base capabilities
}

protocol ConversationProvider: IntelligenceProvider {
    // Adds conversation support
}

protocol RecommendationProvider: IntelligenceProvider {
    // Adds recommendation support
}

protocol EmbeddingProvider: IntelligenceProvider {
    // Adds embedding support
}
```

A provider can conform to multiple protocols:

```swift
final class FoundationModelsProvider: IntelligenceProvider, ConversationProvider {
    // Implements both base and conversation capabilities
}
```

### Use Case Dependencies

Use cases depend on protocols, not implementations:

```swift
public actor ConversationalAssistant {
    private let provider: ConversationProvider

    public init(provider: ConversationProvider) {
        self.provider = provider
    }
}
```

This allows injecting any provider that conforms to `ConversationProvider`.

## Thread Safety

### Actor-Based Concurrency

Stateful components use `actor` for thread safety:

```swift
public actor ConversationalAssistant {
    private var activeConversation: Conversation?

    public func sendMessage(_ text: String) async throws -> String {
        // Actor ensures serial access to activeConversation
    }
}
```

### Sendable Types

All public types conform to `Sendable`:

```swift
public struct Message: Sendable, Identifiable, Codable, Equatable {
    // Can safely cross concurrency boundaries
}

public final class MockIntelligenceProvider: IntelligenceProvider, Sendable {
    // Marked Sendable, uses immutable or thread-safe properties
}
```

## Extension Points

### Custom Providers

Create your own provider by conforming to protocols:

```swift
public final class MyCustomProvider: IntelligenceProvider {
    public let id = "com.myapp.custom"
    public let displayName = "My Custom Provider"
    public let version = "1.0"

    public func isAvailable() async -> Bool {
        // Check availability
    }

    public func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        // Implement completion logic
    }

    public func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        // Implement streaming logic
    }
}
```

### Custom Use Cases

Build custom use cases on top of providers:

```swift
public final class SentimentAnalyzer {
    private let provider: IntelligenceProvider

    public init(provider: IntelligenceProvider) {
        self.provider = provider
    }

    public func analyzeSentiment(_ text: String) async throws -> Sentiment {
        let prompt = "Analyze the sentiment of: \(text)"
        let response = try await provider.complete(
            prompt: prompt,
            configuration: .factual
        )
        return parseSentiment(response.content)
    }
}
```

## Testing Architecture

The architecture makes testing easy:

```swift
@Test("Conversation maintains history")
func conversationMaintainsHistory() async throws {
    // Use mock instead of real provider
    let mock = MockIntelligenceProvider(
        responses: ["Response 1", "Response 2"]
    )

    let assistant = ConversationalAssistant(provider: mock)
    _ = await assistant.startConversation()

    _ = try await assistant.sendMessage("Message 1")
    _ = try await assistant.sendMessage("Message 2")

    let history = try await assistant.conversationHistory()
    #expect(history.count == 4) // 2 user + 2 assistant
}
```

## Performance Considerations

### Lazy Evaluation

Expensive operations are performed lazily:

```swift
// Provider is not called until needed
let provider = ARCIntelligence.foundationModels()

// Only checks availability when you call it
let available = await provider.isAvailable()
```

### Streaming for Long Responses

Use streaming for better user experience:

```swift
// Show chunks as they arrive instead of waiting for complete response
for try await chunk in provider.streamComplete(prompt: "...", configuration: .default) {
    updateUI(with: chunk)
}
```

### Token Estimation

Estimate costs before making requests:

```swift
let counter = TokenCounter()
let estimatedTokens = counter.estimateTokens(for: longText)

if estimatedTokens > maxTokens {
    // Truncate or split the text
}
```

## See Also

- <doc:GettingStarted>
- <doc:CustomProviders>
- <doc:BestPractices>
- ``IntelligenceProvider``
- ``ConversationProvider``
