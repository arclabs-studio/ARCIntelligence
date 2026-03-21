# Choosing an AI Provider

Learn about different AI providers and how to choose the right one for your app.

## Overview

ARCIntelligence supports multiple AI providers, each with different characteristics, capabilities, and trade-offs. This guide helps you choose the right provider for your use case.

## Available Providers

### Foundation Models (iOS 26+ / macOS 26+)

Apple's on-device AI models provide maximum privacy and zero latency.

**Availability:**
- iOS 26.0+
- macOS 26.0+
- Requires compatible hardware

**Supported Protocols:** `IntelligenceProvider`, `ConversationProvider`, `GenerableProvider`, `ToolProvider`, `ContentTaggingProvider`

**Pros:**
- ✅ Complete privacy (on-device processing)
- ✅ Zero latency (no network calls)
- ✅ No API keys required
- ✅ No usage costs
- ✅ Works offline
- ✅ Content tagging (exclusive)

**Cons:**
- ❌ Limited to newer devices
- ❌ Smaller model capabilities vs cloud models
- ❌ Limited context window

**Best for:**
- Privacy-sensitive applications
- Offline-first apps
- Quick, simple completions
- Content tagging and classification

**Example:**

```swift
let provider = ARCIntelligence.foundationModels(
    configuration: FoundationModelsConfiguration(
        defaultTemperature: 0.7,
        maxTokensPerRequest: 2048,
        onDeviceOnly: true  // Ensure no cloud fallback
    )
)

// Check availability before use
guard await provider.isAvailable() else {
    // Fallback to another provider or show message
    return
}

let response = try await provider.complete(
    prompt: "Summarize this text: ...",
    configuration: .default
)
```

---

### Anthropic Claude

Cloud-based access to Claude models (Haiku, Sonnet, Opus).

**Availability:**
- iOS 17.0+ / macOS 14.0+
- Requires API key or AIProxy

**Supported Protocols:** `IntelligenceProvider`, `ConversationProvider`, `GenerableProvider`, `ToolProvider`

**Pros:**
- ✅ Very long context windows (up to 200K tokens)
- ✅ Strong reasoning and code generation
- ✅ Tool calling support
- ✅ Structured JSON output via `GenerableProvider`
- ✅ Works on older devices

**Cons:**
- ❌ Requires API key
- ❌ Data leaves the device
- ❌ Usage costs apply
- ❌ Requires network

**Best for:**
- Complex reasoning tasks
- Long-document analysis
- Applications needing tool calling
- When on-device AI is not available

**Example:**

```swift
let config = AnthropicConfiguration(
    authentication: .apiKey("sk-ant-..."),
    model: .sonnet
)
let provider = ARCIntelligence.anthropic(configuration: config)

let response = try await provider.complete(
    prompt: "Explain quantum entanglement",
    configuration: .factual
)

// For production: use AIProxy to protect your key
let prodProvider = ARCIntelligence.anthropic(
    aiProxyPartialKey: "your-partial-key",
    serviceURL: "https://your-service.aiproxy.pro"
)
```

---

### OpenAI

Cloud-based access to GPT-4o, GPT-4o Mini, and o3-mini.

**Availability:**
- iOS 17.0+ / macOS 14.0+
- Requires API key or AIProxy

**Supported Protocols:** `IntelligenceProvider`, `ConversationProvider`, `GenerableProvider`, `ToolProvider`

**Pros:**
- ✅ Wide model choice (speed vs quality)
- ✅ Strong general-purpose capabilities
- ✅ Tool calling and structured output
- ✅ o3-mini for advanced reasoning

**Cons:**
- ❌ Requires API key
- ❌ Data leaves the device
- ❌ Usage costs apply
- ❌ Requires network

**Best for:**
- General-purpose AI features
- Applications already using OpenAI
- Scenarios needing o3-mini reasoning

**Example:**

```swift
let config = OpenAIConfiguration(
    authentication: .apiKey("sk-..."),
    model: .gpt4o
)
let provider = ARCIntelligence.openAI(configuration: config)

// Tool calling
let toolResponse = try await provider.respondWithToolCalls(
    to: "What's the weather in Madrid?",
    tools: [WeatherTool()],
    configuration: .default
)
print(toolResponse.response.content)
print("Tool calls: \(toolResponse.toolCalls.count)")
```

---

### Grok (xAI)

Cloud-based access to Grok 3 and Grok 3 Fast.

**Availability:**
- iOS 17.0+ / macOS 14.0+
- Requires xAI API key or AIProxy

**Supported Protocols:** `IntelligenceProvider`, `ConversationProvider`, `GenerableProvider`, `ToolProvider`

**Pros:**
- ✅ Fast response times (Grok 3 Fast)
- ✅ Strong reasoning (Grok 3)
- ✅ Tool calling and structured output

**Cons:**
- ❌ Requires xAI API key
- ❌ Data leaves the device
- ❌ Usage costs apply
- ❌ Requires network

**Best for:**
- Speed-sensitive use cases (Grok 3 Fast)
- Applications in xAI's ecosystem

**Example:**

```swift
let config = GrokConfiguration(
    authentication: .apiKey("xai-..."),
    model: .grok3Fast  // or .grok3 for higher quality
)
let provider = ARCIntelligence.grok(configuration: config)

// Guided generation
struct Sentiment: Codable, Sendable {
    let label: String  // "positive", "negative", "neutral"
    let score: Float
}

let sentiment: Sentiment = try await provider.generate(
    Sentiment.self,
    prompt: "Analyze: 'This product is amazing!'",
    configuration: .factual
)
```

---

### Mock Provider (Testing)

Configurable mock for testing without real API calls.

**Availability:**
- Always available
- All platforms

**Supported Protocols:** `IntelligenceProvider`, `ConversationProvider`

**Best for:**
- Unit testing
- UI testing
- Development without API keys
- Continuous integration

**Example:**

```swift
import ARCIntelligenceMocks

let mockProvider = MockIntelligenceProvider(
    responses: ["Mocked response 1", "Mocked response 2"],
    shouldFail: false,
    simulatedDelay: 0.1
)

// For guided generation tests
let generableMock = MockGenerableProvider(
    jsonResponse: #"{"title": "Test Book", "genre": "Fiction"}"#
)

// For tool calling tests
let toolMock = MockToolProvider(
    response: "The weather is sunny",
    toolCallsToSimulate: [
        ToolCallRecord(
            toolName: "getWeather",
            arguments: ["city": "Boston"],
            output: "72°F, Sunny",
            duration: 0.5
        )
    ]
)
```

---

## Provider Comparison

| Feature | Foundation Models | Anthropic | OpenAI | Grok | Mock |
|---------|:---:|:---:|:---:|:---:|:---:|
| Privacy | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Capability | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | N/A |
| Cost | Free | Paid | Paid | Paid | Free |
| Offline | ✅ | ❌ | ❌ | ❌ | ✅ |
| API Key | None | Required | Required | Required | None |
| Min iOS | 26.0 | 17.0 | 17.0 | 17.0 | Any |
| Conversation | ✅ | ✅ | ✅ | ✅ | ✅ |
| Guided Gen | ✅ | ✅ | ✅ | ✅ | ✅ (mock) |
| Tool Calling | ✅ | ✅ | ✅ | ✅ | ✅ (mock) |
| Content Tagging | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## Decision Matrix

### Choose Foundation Models when:
- Privacy is paramount
- Your app needs to work offline
- You want zero API costs
- You need content tagging
- Your minimum iOS version is 26.0+

### Choose Anthropic when:
- You need very long context windows (up to 200K tokens)
- Complex reasoning or detailed analysis is required
- You want one of the most capable models available

### Choose OpenAI when:
- You need a versatile general-purpose model
- You're already integrated with OpenAI in your infrastructure
- o3-mini reasoning tasks are needed

### Choose Grok when:
- Speed is a priority (Grok 3 Fast)
- You're in xAI's ecosystem

### Choose Mock Provider when:
- Writing unit or UI tests
- Developing without API access
- Running CI/CD pipelines

---

## Multi-Provider Strategy

For maximum flexibility, support multiple providers with a runtime fallback:

```swift
func createProvider(preference: ProviderPreference) async -> IntelligenceProvider {
    switch preference {
    case .privacyFirst:
        let provider = ARCIntelligence.foundationModels()
        if await provider.isAvailable() { return provider }
        // Fallback if device doesn't support Foundation Models
        return ARCIntelligence.anthropic(apiKey: storedAPIKey)

    case .powerFirst:
        return ARCIntelligence.anthropic(
            configuration: AnthropicConfiguration(
                authentication: .apiKey(storedAPIKey),
                model: .opus
            )
        )

    case .fastest:
        return ARCIntelligence.grok(
            configuration: GrokConfiguration(
                authentication: .apiKey(storedAPIKey),
                model: .grok3Fast
            )
        )
    }
}
```

---

## Privacy Considerations

### On-Device vs Cloud

**On-Device (Foundation Models):**
- User data never leaves the device
- No network monitoring possible
- Complete user control
- Ideal for sensitive data

**Cloud-Based (Anthropic, OpenAI, Grok):**
- Data sent to third-party servers
- Subject to provider's privacy policy
- May be logged or used for training
- Consider data classification before use

### Best Practices

1. **Default to Privacy**: Use on-device providers when possible
2. **User Choice**: Let users choose their preferred provider
3. **Transparency**: Clearly communicate what data is sent where
4. **Use AIProxy in Production**: Never ship raw API keys in your app
5. **Sanitize**: Remove PII before sending to cloud providers

---

## See Also

- <doc:PrivacyConsiderations>
- <doc:BestPractices>
- ``FoundationModelsProvider``
- ``FoundationModelsConfiguration``
- ``AnthropicProvider``
- ``AnthropicConfiguration``
- ``AnthropicModel``
- ``OpenAIProvider``
- ``OpenAIConfiguration``
- ``OpenAIModel``
- ``GrokProvider``
- ``GrokConfiguration``
- ``GrokModel``
