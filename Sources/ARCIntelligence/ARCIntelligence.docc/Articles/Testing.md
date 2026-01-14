# Testing with ARCIntelligence

Learn how to test your AI-powered features without making real API calls.

## Overview

ARCIntelligence provides comprehensive mock implementations that allow you to test your AI features quickly, reliably, and without incurring API costs or requiring network connectivity.

## Mock Providers

### MockIntelligenceProvider

The primary mock for testing AI completions:

```swift
import Testing
import ARCIntelligence
import ARCIntelligenceMocks

@Test("AI feature generates correct response")
func aiFeatureGeneratesCorrectResponse() async throws {
    // Arrange: Create mock with expected response
    let mockProvider = MockIntelligenceProvider(
        responses: ["Expected AI response"],
        shouldFail: false,
        simulatedDelay: 0.1
    )

    // Act: Use mock in your feature
    let response = try await mockProvider.complete(
        prompt: "Test prompt",
        configuration: .default
    )

    // Assert: Verify the response
    #expect(response.content == "Expected AI response")
    #expect(response.finishReason == .completed)
}
```

### MockConversationProvider

Specialized mock for testing conversations:

```swift
import ARCIntelligenceMocks

@Test("Conversation maintains context")
func conversationMaintainsContext() async throws {
    // Mock that echoes messages back
    let mockProvider = MockConversationProvider(
        responsePrefix: "Echo: "
    )

    let assistant = ConversationalAssistant(provider: mockProvider)
    _ = await assistant.startConversation()

    let response = try await assistant.sendMessage("Hello")

    #expect(response == "Echo: Hello")
}
```

### MockGenerableProvider

Mock for testing structured output generation:

```swift
import ARCIntelligenceMocks

struct MovieReview: Codable, Sendable {
    let title: String
    let rating: Int
}

@Test("Generate structured output")
func generateStructuredOutput() async throws {
    let mock = MockGenerableProvider(
        jsonResponse: #"{"title": "Inception", "rating": 9}"#
    )

    let review: MovieReview = try await mock.generate(
        MovieReview.self,
        prompt: "Review Inception",
        configuration: .default
    )

    #expect(review.title == "Inception")
    #expect(review.rating == 9)
}
```

### MockToolProvider

Mock for testing tool calling workflows:

```swift
import ARCIntelligenceMocks

@Test("Tool provider returns tool calls")
func toolProviderReturnsToolCalls() async throws {
    let mock = MockToolProvider(
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

    let (response, toolCalls) = try await mock.respondWithToolCalls(
        to: "What's the weather?",
        tools: [],
        configuration: .default
    )

    #expect(response.content == "The weather is sunny")
    #expect(toolCalls.count == 1)
    #expect(toolCalls[0].toolName == "getWeather")
}
```

You can also use `MockTool` for testing tool implementations:

```swift
let mockTool = MockTool(
    name: "calculator",
    description: "Performs calculations",
    responseToReturn: "42"
)

let result = try await mockTool.execute(arguments: ["operation": "6*7"])
#expect(result == "42")
```

### MockContentTaggingProvider

Mock for testing content tagging:

```swift
import ARCIntelligenceMocks

@Test("Generate tags for content")
func generateTagsForContent() async throws {
    let mock = MockContentTaggingProvider(
        tagsToReturn: [
            ContentTag(value: "technology", category: .topic, confidence: 0.95),
            ContentTag(value: "excited", category: .emotion, confidence: 0.88)
        ]
    )

    let tags = try await mock.generateTags(
        for: "I love programming!",
        categories: [.topic, .emotion],
        maxTags: 5
    )

    #expect(tags.count == 2)
    #expect(tags[0].value == "technology")
}
```

Use the category-specific initializer for more control:

```swift
let mock = MockContentTaggingProvider(
    tagsByCategory: [
        .topic: ["swift", "ios"],
        .emotion: ["happy", "curious"],
        .action: ["coding", "learning"]
    ]
)
```

Or use convenience factory methods:

```swift
// Standard test tags
let mock = MockContentTaggingProvider.standard()

// Always fails
let failingMock = MockContentTaggingProvider.failing(
    with: .requestFailed("Service unavailable")
)
```

## Testing Patterns

### Testing Success Scenarios

```swift
@Test("Generate summary successfully")
func generateSummarySuccessfully() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["This is a summary of the text."]
    )

    let summarizer = TextSummarizer(provider: mockProvider)
    let summary = try await summarizer.summarize("Long text...")

    #expect(summary.contains("summary"))
}
```

### Testing Error Handling

```swift
@Test("Handle provider unavailable error")
func handleProviderUnavailableError() async throws {
    let mockProvider = MockIntelligenceProvider(
        shouldFail: true  // Simulate failure
    )

    await #expect(throws: IntelligenceError.self) {
        try await mockProvider.complete(
            prompt: "Test",
            configuration: .default
        )
    }
}
```

### Testing Streaming

```swift
@Test("Stream response in chunks")
func streamResponseInChunks() async throws {
    let expectedResponse = "Streamed response"
    let mockProvider = MockIntelligenceProvider(
        responses: [expectedResponse],
        simulatedDelay: 0.01
    )

    var receivedContent = ""
    var chunkCount = 0

    for try await chunk in mockProvider.streamComplete(
        prompt: "Test",
        configuration: .default
    ) {
        receivedContent += chunk
        chunkCount += 1
    }

    #expect(receivedContent == expectedResponse)
    #expect(chunkCount > 0)
}
```

### Testing Conversations

```swift
@Test("Conversation tracks message history")
func conversationTracksMessageHistory() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["Response 1", "Response 2", "Response 3"]
    )

    let assistant = ConversationalAssistant(provider: mockProvider)
    _ = await assistant.startConversation(
        systemPrompt: "You are a helpful assistant"
    )

    _ = try await assistant.sendMessage("Message 1")
    _ = try await assistant.sendMessage("Message 2")
    _ = try await assistant.sendMessage("Message 3")

    let history = try await assistant.conversationHistory()

    // 3 user messages + 3 assistant responses = 6 total
    #expect(history.count == 6)

    // Verify message roles alternate
    #expect(history[0].role == .user)
    #expect(history[1].role == .assistant)
    #expect(history[2].role == .user)
}
```

### Testing Token Limits

```swift
@Test("Handle token limit exceeded")
func handleTokenLimitExceeded() async throws {
    let longText = String(repeating: "a", count: 10000)
    let counter = TokenCounter()

    let estimatedTokens = counter.estimateTokens(for: longText)

    // Verify token estimation
    #expect(estimatedTokens > 1000)

    // Test truncation
    let truncated = counter.truncate(longText, toLimit: 100)
    #expect(truncated.count < longText.count)
}
```

## Mock Configuration Options

### Multiple Responses

The mock can cycle through different responses:

```swift
let mockProvider = MockIntelligenceProvider(
    responses: ["First", "Second", "Third"]
)

// Each call gets a random response from the array
let response1 = try await mockProvider.complete(prompt: "Q1", configuration: .default)
let response2 = try await mockProvider.complete(prompt: "Q2", configuration: .default)
let response3 = try await mockProvider.complete(prompt: "Q3", configuration: .default)

// Responses are randomly selected from ["First", "Second", "Third"]
```

### Simulated Delays

Test time-dependent behavior:

```swift
let slowMock = MockIntelligenceProvider(
    responses: ["Response"],
    simulatedDelay: 2.0  // 2 second delay
)

let start = Date()
let response = try await slowMock.complete(prompt: "Test", configuration: .default)
let duration = Date().timeIntervalSince(start)

#expect(duration >= 2.0)
```

### Failure Simulation

Test error handling:

```swift
let failingMock = MockIntelligenceProvider(
    shouldFail: true
)

do {
    _ = try await failingMock.complete(prompt: "Test", configuration: .default)
    #expect(Bool(false), "Should have thrown an error")
} catch IntelligenceError.requestFailed {
    // Expected error
} catch {
    #expect(Bool(false), "Unexpected error type")
}
```

## Testing Your Custom Features

### Example: Testing a Sentiment Analyzer

```swift
// Your custom feature
class SentimentAnalyzer {
    private let provider: IntelligenceProvider

    init(provider: IntelligenceProvider) {
        self.provider = provider
    }

    func analyze(_ text: String) async throws -> Sentiment {
        let response = try await provider.complete(
            prompt: "Analyze sentiment: \(text)",
            configuration: .factual
        )

        if response.content.lowercased().contains("positive") {
            return .positive
        } else if response.content.lowercased().contains("negative") {
            return .negative
        } else {
            return .neutral
        }
    }
}

enum Sentiment {
    case positive, negative, neutral
}

// Test it
@Test("Sentiment analyzer detects positive sentiment")
func sentimentAnalyzerDetectsPositive() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["The sentiment is positive"]
    )

    let analyzer = SentimentAnalyzer(provider: mockProvider)
    let sentiment = try await analyzer.analyze("Great product!")

    #expect(sentiment == .positive)
}
```

## Integration Testing

### Testing with Real Providers

For integration tests, you can still use real providers but with controlled inputs:

```swift
@Test("Foundation Models integration", .enabled(if: isIntegrationTestEnabled))
func foundationModelsIntegration() async throws {
    let provider = ARCIntelligence.foundationModels()

    guard await provider.isAvailable() else {
        throw XCTSkip("Foundation Models not available")
    }

    let response = try await provider.complete(
        prompt: "Say 'test passed'",
        configuration: .factual
    )

    #expect(!response.content.isEmpty)
}
```

## Best Practices

### 1. Use Mocks by Default

```swift
// ✅ Good: Easy to test, fast, reliable
class MyFeature {
    private let provider: IntelligenceProvider

    init(provider: IntelligenceProvider) {
        self.provider = provider  // Accept protocol, not concrete type
    }
}

// In tests
let feature = MyFeature(provider: MockIntelligenceProvider())

// In production
let feature = MyFeature(provider: ARCIntelligence.foundationModels())
```

### 2. Test Edge Cases

```swift
@Test("Handle empty response")
func handleEmptyResponse() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: [""]  // Empty response
    )

    let response = try await mockProvider.complete(
        prompt: "Test",
        configuration: .default
    )

    #expect(response.content.isEmpty)
}
```

### 3. Test Async Behavior

```swift
@Test("Concurrent requests work correctly")
func concurrentRequestsWork() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["Response"],
        simulatedDelay: 0.1
    )

    // Launch multiple concurrent requests
    async let response1 = mockProvider.complete(prompt: "Q1", configuration: .default)
    async let response2 = mockProvider.complete(prompt: "Q2", configuration: .default)
    async let response3 = mockProvider.complete(prompt: "Q3", configuration: .default)

    // Wait for all
    let responses = try await [response1, response2, response3]

    #expect(responses.count == 3)
}
```

### 4. Verify Provider Behavior

```swift
@Test("Provider availability is checked")
func providerAvailabilityIsChecked() async {
    let mockProvider = MockIntelligenceProvider()

    let available = await mockProvider.isAvailable()

    #expect(available == true)  // Mock is always available
}
```

## Performance Testing

Test that your code handles slow providers gracefully:

```swift
@Test("UI remains responsive during long operation")
func uiRemainsResponsiveDuringLongOperation() async throws {
    let slowMock = MockIntelligenceProvider(
        responses: ["Response"],
        simulatedDelay: 5.0
    )

    // Launch operation
    let task = Task {
        try await slowMock.complete(
            prompt: "Test",
            configuration: .default
        )
    }

    // Verify can do other work while waiting
    await Task.yield()  // Simulate other work

    let response = try await task.value
    #expect(!response.content.isEmpty)
}
```

## See Also

- <doc:BestPractices>
- ``MockIntelligenceProvider``
- ``MockConversationProvider``
- ``MockGenerableProvider``
- ``MockToolProvider``
- ``MockContentTaggingProvider``
- ``MockEmbeddingProvider``
- ``MockRecommendationProvider``
