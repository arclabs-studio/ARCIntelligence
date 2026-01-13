# Choosing an AI Provider

Learn about different AI providers and how to choose the right one for your app.

## Overview

ARCIntelligence supports multiple AI providers, each with different characteristics, capabilities, and trade-offs. This guide helps you choose the right provider for your use case.

## Available Providers

### Foundation Models (iOS 18.0+)

Apple's on-device AI models provide maximum privacy and zero latency.

**Availability:**
- iOS 18.0+
- macOS 15.0+
- Requires compatible hardware

**Pros:**
- ✅ Complete privacy (on-device processing)
- ✅ Zero latency (no network calls)
- ✅ No API keys required
- ✅ No usage costs
- ✅ Works offline

**Cons:**
- ❌ Limited to newer devices
- ❌ Smaller model capabilities
- ❌ Limited context window
- ❌ No custom fine-tuning

**Best for:**
- Privacy-sensitive applications
- Offline-first apps
- Quick, simple completions
- On-device assistant features

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

### Mock Provider (Testing)

Configurable mock for testing without real API calls.

**Availability:**
- Always available
- All platforms

**Pros:**
- ✅ No API calls
- ✅ Deterministic responses
- ✅ Configurable delays
- ✅ Error simulation
- ✅ Fast tests

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

let assistant = ConversationalAssistant(provider: mockProvider)
_ = await assistant.startConversation()
let response = try await assistant.sendMessage("Test")
// response == "Mocked response 1"
```

### Future Providers

Additional providers planned for future releases:

**OpenAI (Coming Soon)**
- GPT-4, GPT-3.5
- Cloud-based
- Powerful language understanding
- Requires API key and network

**Anthropic Claude (Coming Soon)**
- Claude 3 models
- Cloud-based
- Long context windows
- Requires API key and network

**Local LLMs (Planned)**
- llama.cpp integration
- On-device, open-source models
- More powerful than Foundation Models
- Requires larger device resources

## Provider Comparison

| Feature | Foundation Models | Mock | OpenAI* | Anthropic* |
|---------|------------------|------|---------|------------|
| Privacy | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Power | ⭐⭐ | N/A | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Cost | Free | Free | Paid | Paid |
| Offline | Yes | Yes | No | No |
| Setup | None | None | API Key | API Key |
| iOS Version | 18.0+ | Any | Any | Any |

*Coming soon

## Decision Matrix

### Choose Foundation Models when:

- Privacy is paramount
- Your app needs to work offline
- You want zero API costs
- Completions are simple (summarization, categorization)
- Your minimum iOS version is 18.0+

### Choose Mock Provider when:

- Writing unit tests
- Developing without API access
- Running CI/CD pipelines
- Simulating specific scenarios

### Choose Cloud Providers (Future) when:

- You need maximum language understanding
- Complex reasoning is required
- Long context windows are needed
- Privacy is less critical
- Network connectivity is reliable

## Multi-Provider Strategy

For maximum flexibility, support multiple providers:

```swift
enum AIProviderType {
    case foundationModels
    case openAI
    case mock
}

func createProvider(type: AIProviderType) -> IntelligenceProvider {
    switch type {
    case .foundationModels:
        return ARCIntelligence.foundationModels()

    case .openAI:
        // Future: return OpenAIProvider(apiKey: ...)
        fatalError("OpenAI not yet implemented")

    case .mock:
        return MockIntelligenceProvider()
    }
}

// Use provider based on user preference or availability
let preferredType: AIProviderType = .foundationModels
let provider = createProvider(type: preferredType)

if await provider.isAvailable() {
    // Use preferred provider
} else {
    // Fallback to alternative
    let fallbackProvider = createProvider(type: .mock)
}
```

## Privacy Considerations

### On-Device vs Cloud

**On-Device (Foundation Models, Local LLMs):**
- User data never leaves the device
- No network monitoring possible
- Complete user control
- Ideal for sensitive data

**Cloud-Based (OpenAI, Anthropic):**
- Data sent to third-party servers
- Subject to provider's privacy policy
- May be logged or used for training
- Consider data classification

### Best Practices

1. **Default to Privacy**: Use on-device providers when possible
2. **User Choice**: Let users choose their preferred provider
3. **Transparency**: Clearly communicate what data is sent where
4. **Minimize Data**: Only send necessary context
5. **Sanitize**: Remove PII before sending to cloud providers

```swift
// Good: Privacy-first approach
func generateSummary(text: String, userPreference: ProviderPreference) async throws -> String {
    let provider: IntelligenceProvider

    switch userPreference {
    case .privacyFirst:
        provider = ARCIntelligence.foundationModels()

    case .powerFirst:
        // Use cloud provider if available
        provider = createCloudProvider()

    case .balanced:
        // Try on-device first, fallback to cloud
        let onDevice = ARCIntelligence.foundationModels()
        provider = await onDevice.isAvailable() ? onDevice : createCloudProvider()
    }

    let response = try await provider.complete(
        prompt: "Summarize: \(text)",
        configuration: .default
    )

    return response.content
}
```

## Performance Characteristics

### Latency

- **Foundation Models**: < 100ms (on-device)
- **Mock**: Configurable (instant to seconds)
- **OpenAI**: 500ms - 5s (network dependent)
- **Anthropic**: 500ms - 5s (network dependent)

### Throughput

- **Foundation Models**: Limited by device CPU/NPU
- **Cloud Providers**: Limited by API rate limits

### Context Window

- **Foundation Models**: ~2K-4K tokens
- **GPT-4**: Up to 128K tokens
- **Claude 3**: Up to 200K tokens

## Configuration Recommendations

### Foundation Models for Privacy

```swift
let privacyConfig = FoundationModelsConfiguration(
    defaultTemperature: 0.7,
    maxTokensPerRequest: 2048,
    onDeviceOnly: true  // Critical: no cloud fallback
)

let provider = ARCIntelligence.foundationModels(configuration: privacyConfig)
```

### Foundation Models for Performance

```swift
let performanceConfig = FoundationModelsConfiguration(
    defaultTemperature: 0.5,
    maxTokensPerRequest: 4096,
    onDeviceOnly: false  // Allow cloud fallback if needed
)

let provider = ARCIntelligence.foundationModels(configuration: performanceConfig)
```

## See Also

- <doc:PrivacyConsiderations>
- <doc:BestPractices>
- ``FoundationModelsProvider``
- ``FoundationModelsConfiguration``
