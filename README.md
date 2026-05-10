# 🤖 ARCIntelligence

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)
![License](https://img.shields.io/badge/License-PolyForm%20Noncommercial%201.0.0-orange.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)

**Professional AI Capabilities for iOS & macOS Apps**

Protocol-Based Architecture • Swift 6 Concurrency • On-Device AI • Comprehensive Mocks

---

## 🎯 Overview

ARCIntelligence is a Swift package that provides AI-powered features through a clean, protocol-based architecture. Abstract different AI providers (Apple Foundation Models, OpenAI, Anthropic) behind unified interfaces with maximum privacy and performance.

The package is designed following Clean Architecture principles, making it easy to swap AI providers without changing your application code. It fully embraces Swift 6 concurrency with `async/await` and `Sendable` compliance throughout.

### Key Features

- ✅ **Protocol-Based Architecture** - Easy to swap AI providers without changing your code
- ✅ **Apple Foundation Models** - Privacy-first, on-device AI (iOS 26+)
- ✅ **Conversational AI** - Multi-turn dialogue management with context preservation
- ✅ **Guided Generation** - Generate structured Swift types with `@Generable` support
- ✅ **Tool Calling** - Extend model capabilities with custom tools
- ✅ **Content Tagging** - Extract topics, emotions, and actions from text
- ✅ **Recommendations Engine** - Personalized suggestions based on user context
- ✅ **Semantic Search** - Vector-based similarity search with embeddings
- ✅ **Session Transcripts** - Observable history of interactions with persistence support
- ✅ **Swift 6 Concurrency** - Full `async/await` and `Sendable` compliance
- ✅ **Comprehensive Mocks** - Test your AI features without making real API calls

---

## 📋 Requirements

- **Swift:** 6.0+
- **Platforms:** iOS 17.0+ / macOS 14.0+
- **Xcode:** 16.0+
- **Tools:** SwiftLint, SwiftFormat (via ARCDevTools)

---

## 🚀 Installation

### Swift Package Manager

#### For Swift Packages

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCIntelligence", from: "1.0.0")
]
```

#### For Xcode Projects

1. **File → Add Package Dependencies**
2. Enter: `https://github.com/arclabs-studio/ARCIntelligence`
3. Select version: `1.0.0` or later
4. **Add to target**

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["ARCIntelligence"]
)
```

---

## 📖 Usage

### Quick Start

```swift
import ARCIntelligence

// Create a provider
let provider = ARCIntelligence.foundationModels()

// Check availability
guard await provider.isAvailable() else {
    print("Foundation Models not available")
    return
}

// Generate a completion
let response = try await provider.complete(
    prompt: "Explain quantum computing in simple terms",
    configuration: .factual
)

print(response.content)
```

### Conversational Assistant

```swift
import ARCIntelligence

// Create provider and assistant
let provider = ARCIntelligence.foundationModels()
let assistant = ARCIntelligence.conversationalAssistant(provider: provider)

// Start a conversation
let conversation = await assistant.startConversation(
    systemPrompt: "You are a helpful coding assistant"
)

// Send messages
let response1 = try await assistant.sendMessage("What is SwiftUI?")
print(response1)

let response2 = try await assistant.sendMessage("Show me an example")
print(response2)

// Get conversation history
let history = try await assistant.conversationHistory()
print("Total messages: \(history.count)")

// End conversation
await assistant.endConversation()
```

### Streaming Responses

```swift
import ARCIntelligence

let provider = ARCIntelligence.foundationModels()

for try await chunk in provider.streamComplete(
    prompt: "Write a short story about AI",
    configuration: .creative
) {
    print(chunk, terminator: "")
}
```

### Recommendations

```swift
import ARCIntelligence

// Your custom context type
struct UserContext: Codable, Sendable {
    let viewedItems: [String]
    let preferences: [String]
}

let provider = /* your recommendation provider */
let engine = ARCIntelligence.recommendationEngine(provider: provider)

let context = UserContext(
    viewedItems: ["item1", "item2"],
    preferences: ["category1", "category2"]
)

let recommendations = try await engine.recommend(
    basedOn: context,
    numberOfRecommendations: 5,
    configuration: .diverse
)

for recommendation in recommendations {
    print("\(recommendation.title): \(recommendation.confidence)")
}
```

### Semantic Search

```swift
import ARCIntelligence

let provider = /* your embedding provider */
let search = ARCIntelligence.semanticSearch(provider: provider)

let candidates = [
    "Swift is a programming language",
    "Python is used for data science",
    "JavaScript runs in browsers"
]

let results = try await search.search(
    query: "programming languages",
    in: candidates,
    topK: 2
)

for (text, similarity) in results {
    print("\(text) - Similarity: \(similarity)")
}
```

### Guided Generation

Generate structured Swift types directly from prompts:

```swift
import ARCIntelligence

// Define your output type
struct MovieReview: Codable, Sendable {
    let title: String
    let rating: Int
    let summary: String
    let pros: [String]
    let cons: [String]
}

// Create the provider
let provider = ARCIntelligence.generableProvider()

// Generate structured data
let review: MovieReview = try await provider.generate(
    MovieReview.self,
    prompt: "Review the movie Inception",
    configuration: .factual
)

print("\(review.title): \(review.rating)/10")
print("Pros: \(review.pros.joined(separator: ", "))")
```

### Google Gemini

Direct access to Google AI Studio with automatic retry and streaming support:

```swift
import ARCIntelligence

// Quick setup
let provider = ARCIntelligence.gemini(apiKey: "AIza...")

// Or with a specific model / preset
let config = GeminiConfiguration.quality(authentication: .apiKey("AIza..."))
let qualityProvider = ARCIntelligence.gemini(configuration: config)

// Streaming completion
for try await chunk in provider.streamComplete(
    prompt: "Explain machine learning",
    configuration: .default
) {
    print(chunk, terminator: "")
}

// Structured generation (Generable)
struct Recipe: Codable, Sendable {
    let name: String
    let ingredients: [String]
    let steps: [String]
}

let genProvider = ARCIntelligence.generableProvider(geminiConfiguration: config)
let recipe: Recipe = try await genProvider.generate(
    Recipe.self,
    prompt: "Give me a pasta recipe",
    configuration: .default
)
print(recipe.name)

// For production: use AIProxy to protect your key
let prodProvider = ARCIntelligence.gemini(
    aiProxyPartialKey: "your-partial-key",
    serviceURL: "https://your-service.aiproxy.pro"
)
```

### Tool Calling

Extend model capabilities with custom tools:

```swift
import ARCIntelligence

// Define a tool
struct WeatherTool: IntelligenceTool {
    let name = "getWeather"
    let description = "Get current weather for a city"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(
            parameters: [
                ToolParameter(
                    name: "city",
                    type: .string,
                    description: "The city name"
                )
            ],
            required: ["city"]
        )
    }

    func execute(arguments: [String: ToolArgumentValue]) async throws -> String {
        let city = arguments["city"]?.stringValue ?? "Unknown"
        // Call your weather API here
        return "Weather in \(city): 72°F, Sunny"
    }
}

// Use the provider with tools
let provider = ARCIntelligence.toolProvider()
let response = try await provider.respond(
    to: "What's the weather in San Francisco?",
    tools: [WeatherTool()],
    configuration: .default
)

print(response.content)
```

### Content Tagging

Extract topics, emotions, and actions from text:

```swift
import ARCIntelligence

let provider = ARCIntelligence.contentTaggingProvider()

let tags = try await provider.generateTags(
    for: "I love hiking in the mountains on sunny days!",
    categories: [.topic, .emotion, .action],
    maxTags: 5
)

for tag in tags {
    print("\(tag.category): \(tag.value) (\(tag.confidence))")
}
// Output:
// topic: hiking (0.95)
// topic: mountains (0.90)
// emotion: joy (0.88)
// action: outdoor activity (0.85)
```

### Session Transcript

Track conversation history with observable transcripts:

```swift
import ARCIntelligence

// Access transcript from a conversation
let transcript = await assistant.transcript

// Iterate over entries
for entry in transcript.entries {
    switch entry {
    case .prompt(let prompt):
        print("User: \(prompt.content)")
    case .response(let response):
        print("Assistant: \(response.content)")
    case .toolCall(let call):
        print("Tool Call: \(call.toolName)")
    case .toolOutput(let output):
        print("Tool Output: \(output.content)")
    case .instructions(let instructions):
        print("System: \(instructions.content)")
    }
}

// Persist transcript
let data = try JSONEncoder().encode(transcript)
```

### Advanced Usage

```swift
// Custom provider configuration
let config = FoundationModelsConfiguration(
    defaultTemperature: 0.8,
    maxTokensPerRequest: 4096,
    onDeviceOnly: true
)

let provider = ARCIntelligence.foundationModels(configuration: config)

// Prompt building
let prompt = PromptBuilder()
    .withSystemInstruction("You are an expert programmer")
    .withContext("User is learning Swift")
    .withQuery("Explain optionals")
    .build()

// Token management
let counter = TokenCounter()
let estimatedTokens = counter.estimateTokens(for: text)

if counter.fitsWithinLimit(text, limit: 1000) {
    // Proceed with request
} else {
    let truncated = counter.truncate(text, toLimit: 1000)
}
```

---

## 🏗️ Architecture

### Core Protocols

- **`IntelligenceProvider`** - Base protocol for all AI providers
- **`ConversationProvider`** - Multi-turn conversations with context
- **`RecommendationProvider`** - Context-based recommendations
- **`EmbeddingProvider`** - Vector embeddings for semantic search
- **`GenerableProvider`** - Structured output generation (iOS 26+)
- **`ToolProvider`** - Tool calling and function execution
- **`ContentTaggingProvider`** - Text analysis and tagging

### Providers

- **`FoundationModelsProvider`** - Apple's on-device AI (iOS 26+)
- **`AnthropicProvider`** - Anthropic Claude (Haiku, Sonnet, Opus)
- **`OpenAIProvider`** - OpenAI GPT-4o and o3-mini
- **`GrokProvider`** - xAI Grok 3 and Grok 3 Fast
- **`GeminiProvider`** - Google Gemini 2.0 Flash, 1.5 Pro via native v1 REST API

### Use Cases

High-level APIs for common AI tasks:

- **`ConversationalAssistant`** - Manages multi-turn dialogues
- **`RecommendationEngine`** - Generates personalized suggestions
- **`SemanticSearch`** - Vector-based similarity search

### Models

Core data types:

- **`Message`** - Single message in a conversation
- **`Conversation`** - Multi-turn conversation with history
- **`Recommendation`** - Single recommendation with confidence
- **`Embedding`** - Vector representation of text
- **`IntelligenceResponse`** - Completion response with metadata
- **`CompletionConfiguration`** - Configuration for text generation
- **`SessionTranscript`** - Observable history of session interactions
- **`TranscriptEntry`** - Individual entry (prompt, response, tool call, etc.)
- **`ContentTag`** - Tag with category and confidence score
- **`TagCategory`** - Tag categories (topic, action, object, emotion)
- **`IntelligenceTool`** - Protocol for custom tool definitions
- **`ToolCallRecord`** - Record of tool execution with timing

### Utilities

- **`PromptBuilder`** - Construct well-formatted prompts
- **`TokenCounter`** - Estimate token usage

For complete architecture guidelines, see [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge).

---

## 🧪 Testing

ARCIntelligence provides comprehensive mocks for testing:

```swift
import Testing
import ARCIntelligence
import ARCIntelligenceMocks

@Test("My AI feature works")
func myAIFeatureWorks() async throws {
    // Use mock provider for testing
    let mockProvider = MockIntelligenceProvider(
        responses: ["Expected response"],
        shouldFail: false,
        simulatedDelay: 0.1
    )

    let assistant = ConversationalAssistant(provider: mockProvider)
    _ = await assistant.startConversation()

    let response = try await assistant.sendMessage("Test")
    #expect(response == "Expected response")
}
```

### Mock Providers

- **`MockIntelligenceProvider`** - Configurable mock with canned responses
- **`MockConversationProvider`** - Echo-style conversation for testing
- **`MockEmbeddingProvider`** - Mock embeddings for semantic search testing
- **`MockRecommendationProvider`** - Mock recommendations for engine testing
- **`MockGenerableProvider`** - Mock structured output generation
- **`MockToolProvider`** - Mock tool calling with configurable results
- **`MockContentTaggingProvider`** - Mock content tagging for text analysis

### Coverage

- **Packages:** Target 100%, minimum 80%
- **Apps:** Target 80%+

---

## 🛠️ Development

### Prerequisites

```bash
# Install required tools
brew install swiftlint swiftformat
```

### Setup

```bash
# Clone the repository
git clone https://github.com/arclabs-studio/ARCIntelligence.git
cd ARCIntelligence

# Initialize submodules
git submodule update --init --recursive

# Run ARCDevTools setup
./ARCDevTools/arcdevtools-setup

# Build the project
swift build
```

### Available Commands

```bash
make help          # Show all available commands
make lint          # Run SwiftLint
make format        # Preview formatting changes
make fix           # Apply SwiftFormat
make test          # Run tests
make clean         # Remove build artifacts
```

### Example App

Check out the [ARCIntelligenceShowcase](Examples/ARCIntelligenceShowcase/) app for a complete, interactive demonstration of all features:

```bash
cd Examples/ARCIntelligenceShowcase
open Package.swift
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Create a feature branch: `feature/ARC-XXX-description`
2. Follow [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge) standards
3. Ensure tests pass: `swift test`
4. Run quality checks: `make lint && make format`
5. Create a pull request

### Commit Messages

Follow [Conventional Commits](https://github.com/arclabs-studio/ARCKnowledge/blob/main/Workflow/git-commits.md):

```
feat(core): add new embedding provider
fix(assistant): resolve conversation state issue
docs: update installation instructions
```

---

## 📦 Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes
- **MINOR** - New features (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## 📄 License

**PolyForm Noncommercial License 1.0.0** © 2025–2026 ARC Labs Studio.

Source-available. Free for non-commercial use (research, study, hobby, evaluation). **Commercial use requires a separate license** — contact `arclabs.studio@gmail.com`.

ARC Labs Studio's own commercial products are covered by an internal use grant — see [INTERNAL-USE.md](INTERNAL-USE.md).

See [LICENSE](LICENSE) for the full license text.

---

## 🔗 Related Resources

- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** - Development standards and guidelines
- **[ARCDevTools](https://github.com/arclabs-studio/ARCDevTools)** - Quality tooling and automation
- **[ARCLogger](https://github.com/arclabs-studio/ARCLogger)** - Structured logging framework

---

<div align="center">

Made with 💛 by ARC Labs Studio

[**Website**](https://arclabs.studio) • [**GitHub**](https://github.com/arclabs-studio) • [**Issues**](https://github.com/arclabs-studio/ARCIntelligence/issues)

</div>
