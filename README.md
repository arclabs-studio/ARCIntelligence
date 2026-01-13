# 🧠 ARCIntelligence

**Professional AI Capabilities for iOS & macOS Apps**

ARCIntelligence is a Swift package that provides AI-powered features through a clean, protocol-based architecture. Abstract different AI providers (Apple Foundation Models, OpenAI, Anthropic) behind unified interfaces with maximum privacy and performance.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue.svg)

---

## ✨ Features

- **Protocol-Based Architecture**: Easy to swap AI providers without changing your code
- **Apple Foundation Models**: Privacy-first, on-device AI (iOS 18.0+)
- **Conversational AI**: Multi-turn dialogue management with context preservation
- **Recommendations Engine**: Personalized suggestions based on user context
- **Semantic Search**: Vector-based similarity search with embeddings
- **Swift 6 Concurrency**: Full `async/await` and `Sendable` compliance
- **Comprehensive Mocks**: Test your AI features without making real API calls
- **Zero External Dependencies**: Pure Swift, no third-party libraries

---

## 📋 Requirements

- **iOS**: 17.0+
- **macOS**: 14.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

---

## 📦 Installation

### Swift Package Manager

Add ARCIntelligence to your project using Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/arclabs-studio/ARCIntelligence.git`
3. Select version or branch

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCIntelligence.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["ARCIntelligence"]
)
```

---

## 📱 Example App

**NEW**: Check out the [ARCIntelligenceShowcase](Examples/ARCIntelligenceShowcase/) app for a complete, interactive demonstration of all features!

The showcase app includes:
- ✅ Text completions with different configurations
- ✅ Real-time streaming responses
- ✅ Multi-turn conversations
- ✅ Prompt builder and token counter utilities
- ✅ Provider switching (Mock vs Foundation Models)
- ✅ Complete SwiftUI implementation

**Quick Start:**
```bash
cd Examples/ARCIntelligenceShowcase
open Package.swift
```

---

## 🚀 Quick Start

### Basic Completion

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
    count: 5,
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

---

## 🏗 Architecture

### Core Protocols

- **`IntelligenceProvider`**: Base protocol for all AI providers
- **`ConversationProvider`**: Multi-turn conversations with context
- **`RecommendationProvider`**: Context-based recommendations
- **`EmbeddingProvider`**: Vector embeddings for semantic search

### Providers

- **`FoundationModelsProvider`**: Apple's on-device AI (iOS 18.0+)
- More providers coming soon (OpenAI, Anthropic, etc.)

### Use Cases

High-level APIs for common AI tasks:

- **`ConversationalAssistant`**: Manages multi-turn dialogues
- **`RecommendationEngine`**: Generates personalized suggestions
- **`SemanticSearch`**: Vector-based similarity search

### Models

Core data types:

- **`Message`**: Single message in a conversation
- **`Conversation`**: Multi-turn conversation with history
- **`Recommendation`**: Single recommendation with confidence
- **`Embedding`**: Vector representation of text
- **`IntelligenceResponse`**: Completion response with metadata
- **`CompletionConfiguration`**: Configuration for text generation

### Utilities

- **`PromptBuilder`**: Construct well-formatted prompts
- **`TokenCounter`**: Estimate token usage

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

- **`MockIntelligenceProvider`**: Configurable mock with canned responses
- **`MockConversationProvider`**: Echo-style conversation for testing

---

## 📚 Advanced Usage

### Custom Configuration

```swift
let config = FoundationModelsConfiguration(
    defaultTemperature: 0.8,
    maxTokensPerRequest: 4096,
    onDeviceOnly: true
)

let provider = ARCIntelligence.foundationModels(configuration: config)
```

### Completion Presets

```swift
// Factual, low-temperature responses
let factual = try await provider.complete(
    prompt: "What is the capital of France?",
    configuration: .factual
)

// Creative, high-temperature responses
let creative = try await provider.complete(
    prompt: "Write a poem about coding",
    configuration: .creative
)

// Custom configuration
let custom = CompletionConfiguration(
    temperature: 0.8,
    maxTokens: 500,
    systemPrompt: "You are a helpful assistant",
    stopSequences: ["END"],
    topP: 0.95
)
```

### Prompt Building

```swift
let prompt = PromptBuilder()
    .withSystemInstruction("You are an expert programmer")
    .withContext("User is learning Swift")
    .withQuery("Explain optionals")
    .build()

let response = try await provider.complete(
    prompt: prompt,
    configuration: .default
)
```

### Token Management

```swift
let counter = TokenCounter()

let text = "Some long text..."
let estimatedTokens = counter.estimateTokens(for: text)

if counter.fitsWithinLimit(text, limit: 1000) {
    // Proceed with request
} else {
    // Truncate or split
    let truncated = counter.truncate(text, toLimit: 1000)
}
```

---

## 🔒 Privacy

ARCIntelligence prioritizes user privacy:

- **On-Device Processing**: Foundation Models run entirely on-device (iOS 18.0+)
- **No Data Collection**: Zero telemetry or analytics
- **No External Dependencies**: Pure Swift, no third-party SDKs
- **User Control**: Easy to switch providers based on privacy requirements

---

## 🗺 Roadmap

- [ ] OpenAI provider implementation
- [ ] Anthropic Claude provider
- [ ] Local LLM support (llama.cpp integration)
- [ ] Multi-modal support (images, audio)
- [ ] Caching layer for responses
- [ ] Rate limiting utilities
- [ ] Prompt template system
- [ ] Analytics hooks (opt-in)

---

## 🤝 Contributing

We welcome contributions from the community! Please follow these guidelines:

1. **Code Style**: Follow the standards in `CLAUDE.md`
2. **Testing**: Maintain 100% test coverage for core features
3. **Documentation**: Add DocC comments for all public APIs
4. **SwiftLint**: Ensure zero violations
5. **One Type Per File**: Follow our file organization rules

### Development Setup

```bash
# Clone the repository
git clone https://github.com/arclabs-studio/ARCIntelligence.git
cd ARCIntelligence

# Build the package
swift build

# Run tests
swift test

# Run SwiftLint
swiftlint
```

---

## 📄 License

ARCIntelligence is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

**ARCIntelligence** is developed and maintained by [ARC Labs Studio](https://github.com/arclabs-studio).

### Special Thanks

- Apple for Foundation Models and Swift
- The Swift community for excellent tools and libraries

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/arclabs-studio/ARCIntelligence/issues)
- **Discussions**: [GitHub Discussions](https://github.com/arclabs-studio/ARCIntelligence/discussions)
- **Email**: support@arclabs.studio

---

## 📖 Documentation

Full API documentation is available via DocC:

```bash
swift package generate-documentation
```

Or visit our [online documentation](https://arclabs-studio.github.io/ARCIntelligence/documentation/arcintelligence/).

---

**Built with ❤️ by ARC Labs Studio**
