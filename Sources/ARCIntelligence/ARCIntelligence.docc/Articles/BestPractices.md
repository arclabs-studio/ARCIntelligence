# Best Practices

Follow these best practices when using ARCIntelligence in your applications.

## Overview

This guide covers recommended patterns and practices for integrating AI capabilities into your iOS and macOS applications using ARCIntelligence.

## Provider Selection

### Use Protocol Types

Always depend on protocols, not concrete implementations:

```swift
// ✅ Good: Depends on protocol
class ChatViewController: UIViewController {
    private let provider: ConversationProvider

    init(provider: ConversationProvider) {
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
    }
}

// ❌ Bad: Depends on concrete type
class ChatViewController: UIViewController {
    private let provider: FoundationModelsProvider  // Hard to test, inflexible

    init(provider: FoundationModelsProvider) {
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
    }
}
```

### Check Availability

Always verify provider availability before use:

```swift
// ✅ Good: Checks availability
func setupAI() async {
    let provider = ARCIntelligence.foundationModels()

    guard await provider.isAvailable() else {
        showFallbackUI()
        return
    }

    // Provider is available, proceed
}

// ❌ Bad: Assumes availability
func setupAI() async {
    let provider = ARCIntelligence.foundationModels()
    // Might fail at runtime if provider is unavailable
}
```

### Provide Fallbacks

Have a fallback strategy when providers are unavailable:

```swift
func getProvider() async -> IntelligenceProvider {
    // Try Foundation Models first
    let foundationProvider = ARCIntelligence.foundationModels()
    if await foundationProvider.isAvailable() {
        return foundationProvider
    }

    // Fallback to cloud provider if user consents
    if await hasCloudConsent() {
        return createCloudProvider()
    }

    // Final fallback: limited functionality
    return MockIntelligenceProvider(
        responses: ["AI features are currently unavailable"]
    )
}
```

## Error Handling

### Handle All Error Cases

```swift
// ✅ Good: Comprehensive error handling
func generateCompletion(_ prompt: String) async -> String {
    do {
        let response = try await provider.complete(
            prompt: prompt,
            configuration: .default
        )
        return response.content

    } catch IntelligenceError.providerUnavailable {
        return "AI is not available on this device"

    } catch IntelligenceError.tokenLimitExceeded(let current, let max) {
        return "Input too long (\(current) tokens, max: \(max))"

    } catch IntelligenceError.rateLimitExceeded {
        return "Too many requests. Please try again later."

    } catch IntelligenceError.authenticationFailed {
        return "Authentication error. Please check your API key."

    } catch {
        return "An unexpected error occurred: \(error.localizedDescription)"
    }
}

// ❌ Bad: Generic error handling
func generateCompletion(_ prompt: String) async -> String {
    do {
        let response = try await provider.complete(prompt: prompt, configuration: .default)
        return response.content
    } catch {
        return "Error"  // Not helpful to users
    }
}
```

### Graceful Degradation

```swift
func enhanceText(_ text: String) async -> String {
    do {
        // Try AI enhancement
        let response = try await provider.complete(
            prompt: "Enhance this text: \(text)",
            configuration: .default
        )
        return response.content

    } catch {
        // Fallback: return original text
        print("AI enhancement failed: \(error)")
        return text  // Graceful degradation
    }
}
```

## Performance

### Use Streaming for Long Responses

```swift
// ✅ Good: Stream for better UX
func generateLongContent(_ prompt: String) async {
    var accumulatedText = ""

    do {
        for try await chunk in provider.streamComplete(
            prompt: prompt,
            configuration: .default
        ) {
            accumulatedText += chunk
            updateUI(with: accumulatedText)  // Update UI incrementally
        }
    } catch {
        handleError(error)
    }
}

// ❌ Bad: Wait for entire response
func generateLongContent(_ prompt: String) async {
    do {
        let response = try await provider.complete(
            prompt: prompt,
            configuration: .default
        )
        updateUI(with: response.content)  // User waits for entire response
    } catch {
        handleError(error)
    }
}
```

### Estimate Tokens Before Requests

```swift
// ✅ Good: Check token count first
func processText(_ text: String) async throws -> String {
    let counter = TokenCounter()
    let estimatedTokens = counter.estimateTokens(for: text)

    let maxTokens = 4096

    if estimatedTokens > maxTokens {
        // Truncate or split
        let truncated = counter.truncate(text, toLimit: maxTokens)
        return try await provider.complete(
            prompt: truncated,
            configuration: .default
        ).content
    }

    return try await provider.complete(
        prompt: text,
        configuration: .default
    ).content
}
```

### Cache Expensive Results

```swift
actor ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let maxAge: TimeInterval = 3600  // 1 hour

    func get(_ key: String) -> String? {
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < maxAge else {
            return nil
        }
        return cached.response
    }

    func set(_ key: String, response: String) {
        cache[key] = CachedResponse(response: response, timestamp: Date())

        // Limit cache size
        if cache.count > 100 {
            let oldestKey = cache.min { $0.value.timestamp < $1.value.timestamp }?.key
            cache.removeValue(forKey: oldestKey ?? "")
        }
    }
}

struct CachedResponse {
    let response: String
    let timestamp: Date
}

// Usage
let cache = ResponseCache()

func getCachedCompletion(_ prompt: String) async throws -> String {
    // Check cache first
    if let cached = await cache.get(prompt) {
        return cached
    }

    // Generate new response
    let response = try await provider.complete(
        prompt: prompt,
        configuration: .default
    )

    // Cache result
    await cache.set(prompt, response: response.content)

    return response.content
}
```

## Prompt Engineering

### Use Clear, Specific Prompts

```swift
// ✅ Good: Clear and specific
let prompt = """
Summarize the following article in 3 bullet points.
Focus on the main findings and conclusions.

Article:
\(articleText)

Summary:
"""

// ❌ Bad: Vague
let prompt = "Summarize this: \(articleText)"
```

### Use PromptBuilder

```swift
// ✅ Good: Structured prompt
let prompt = PromptBuilder()
    .withSystemInstruction("You are a helpful programming assistant")
    .withContext("User is a Swift beginner learning iOS development")
    .withQuery("Explain optionals in Swift")
    .build()

let response = try await provider.complete(
    prompt: prompt,
    configuration: .default
)
```

### Include Examples

```swift
// ✅ Good: Few-shot learning with examples
let prompt = """
Classify the sentiment of customer reviews.

Examples:
Review: "Great product, very happy!"
Sentiment: Positive

Review: "Terrible, doesn't work at all"
Sentiment: Negative

Review: "It's okay, nothing special"
Sentiment: Neutral

Now classify:
Review: "\(customerReview)"
Sentiment:
"""
```

## Configuration

### Choose Appropriate Presets

```swift
// For factual queries
let factualResponse = try await provider.complete(
    prompt: "What is the capital of France?",
    configuration: .factual  // Low temperature, deterministic
)

// For creative tasks
let creativeResponse = try await provider.complete(
    prompt: "Write a poem about coding",
    configuration: .creative  // High temperature, more varied
)
```

### Configure for Use Case

```swift
// For chatbots: balanced creativity
let chatConfig = CompletionConfiguration(
    temperature: 0.7,
    maxTokens: 500
)

// For code generation: lower temperature
let codeConfig = CompletionConfiguration(
    temperature: 0.2,
    maxTokens: 1000
)

// For creative writing: higher temperature
let creativeConfig = CompletionConfiguration(
    temperature: 0.9,
    maxTokens: 2000,
    topP: 0.95
)
```

## Conversation Management

### Use ConversationalAssistant

```swift
// ✅ Good: Use the assistant for conversations
let assistant = ARCIntelligence.conversationalAssistant(
    provider: provider
)

_ = await assistant.startConversation(
    systemPrompt: "You are a helpful assistant"
)

let response1 = try await assistant.sendMessage("Hello")
let response2 = try await assistant.sendMessage("Tell me more")

// Assistant maintains context automatically
```

### Set Clear System Prompts

```swift
// ✅ Good: Clear role definition
let systemPrompt = """
You are a Swift programming expert assistant.
- Provide concise, accurate answers
- Include code examples when helpful
- Explain complex concepts simply
- Ask clarifying questions when needed
"""

_ = await assistant.startConversation(systemPrompt: systemPrompt)
```

### Clean Up Conversations

```swift
// ✅ Good: Clean up when done
func handleChatSession() async {
    let assistant = ARCIntelligence.conversationalAssistant(provider: provider)

    _ = await assistant.startConversation()

    // ... chat session ...

    // Clean up when user leaves
    await assistant.endConversation()
}
```

## Testing

### Use Mocks in Tests

```swift
// ✅ Good: Test with mocks
@Test("Feature works correctly")
func featureWorksCorrectly() async throws {
    let mockProvider = MockIntelligenceProvider(
        responses: ["Expected response"]
    )

    let feature = MyFeature(provider: mockProvider)
    let result = try await feature.process("input")

    #expect(result == "Expected response")
}

// ❌ Bad: Test with real provider
@Test("Feature works correctly")
func featureWorksCorrectly() async throws {
    let realProvider = ARCIntelligence.foundationModels()
    // Test is slow, flaky, requires device with Foundation Models
}
```

### Test Error Cases

```swift
@Test("Handles provider failures")
func handlesProviderFailures() async throws {
    let failingProvider = MockIntelligenceProvider(
        shouldFail: true
    )

    let feature = MyFeature(provider: failingProvider)

    await #expect(throws: IntelligenceError.self) {
        try await feature.process("input")
    }
}
```

## UI/UX Considerations

### Show Loading States

```swift
@MainActor
class ChatViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var messages: [Message] = []

    func sendMessage(_ text: String) async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let response = try await assistant.sendMessage(text)
            messages.append(Message(role: .user, content: text))
            messages.append(Message(role: .assistant, content: response))
        } catch {
            // Handle error
        }
    }
}

// In SwiftUI view
if viewModel.isGenerating {
    ProgressView("Thinking...")
}
```

### Handle Long Operations

```swift
// ✅ Good: Allow cancellation
class AIProcessor {
    private var currentTask: Task<String, Error>?

    func process(_ input: String) async throws -> String {
        let task = Task {
            try await provider.complete(
                prompt: input,
                configuration: .default
            ).content
        }

        currentTask = task
        defer { currentTask = nil }

        return try await task.value
    }

    func cancel() {
        currentTask?.cancel()
    }
}
```

### Provide Feedback

```swift
// ✅ Good: Stream with progress updates
func generateWithProgress(_ prompt: String, progress: @escaping (String) -> Void) async throws -> String {
    var full = ""

    for try await chunk in provider.streamComplete(
        prompt: prompt,
        configuration: .default
    ) {
        full += chunk
        progress(full)  // Update UI progressively
    }

    return full
}
```

## Security

### Validate User Input

```swift
// ✅ Good: Validate and sanitize
func processUserInput(_ input: String) async throws -> String {
    guard !input.isEmpty else {
        throw IntelligenceError.invalidRequest("Input cannot be empty")
    }

    guard input.count <= 10_000 else {
        throw IntelligenceError.invalidRequest("Input too long")
    }

    // Sanitize input
    let sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)

    return try await provider.complete(
        prompt: sanitized,
        configuration: .default
    ).content
}
```

### Don't Log Sensitive Data

```swift
// ✅ Good: Sanitized logging
func complete(_ prompt: String) async throws -> String {
    print("Processing prompt of length: \(prompt.count)")  // Safe

    let response = try await provider.complete(
        prompt: prompt,
        configuration: .default
    )

    print("Received response of length: \(response.content.count)")  // Safe

    return response.content
}

// ❌ Bad: Logging sensitive data
func complete(_ prompt: String) async throws -> String {
    print("Prompt: \(prompt)")  // Logs user data!

    let response = try await provider.complete(
        prompt: prompt,
        configuration: .default
    )

    print("Response: \(response.content)")  // Logs AI response!

    return response.content
}
```

### Protect API Keys

```swift
// ✅ Good: Secure storage
import Security

class KeychainManager {
    static func saveAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ai-api-key",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)  // Remove old
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw IntelligenceError.authenticationFailed
        }
    }
}

// ❌ Bad: Hardcoded keys
let provider = CustomProvider(apiKey: "sk-1234567890")  // Never do this!
```

## Resource Management

### Clean Up Resources

```swift
// ✅ Good: Proper cleanup
class AIService {
    private let provider: IntelligenceProvider
    private var tasks: [Task<Void, Never>] = []

    deinit {
        // Cancel ongoing tasks
        tasks.forEach { $0.cancel() }
    }
}
```

### Limit Concurrent Requests

```swift
actor RequestLimiter {
    private var activeRequests = 0
    private let maxConcurrent = 3

    func withLimit<T>(_ operation: () async throws -> T) async throws -> T {
        // Wait if at limit
        while activeRequests >= maxConcurrent {
            try await Task.sleep(for: .milliseconds(100))
        }

        activeRequests += 1
        defer { activeRequests -= 1 }

        return try await operation()
    }
}

// Usage
let limiter = RequestLimiter()

let result = try await limiter.withLimit {
    try await provider.complete(prompt: "...", configuration: .default)
}
```

## Accessibility

### Provide Alternative Interactions

```swift
// ✅ Good: Alternative for AI features
func getFeatureSuggestion() async -> String {
    do {
        // Try AI suggestion
        let response = try await provider.complete(
            prompt: "Suggest a feature",
            configuration: .default
        )
        return response.content

    } catch {
        // Fallback: predefined suggestions
        return getManualSuggestions().randomElement() ?? "No suggestion"
    }
}
```

### Support VoiceOver

```swift
// In SwiftUI
Text(aiResponse)
    .accessibilityLabel("AI Response")
    .accessibilityHint("AI-generated content based on your query")
```

## See Also

- <doc:Architecture>
- <doc:Testing>
- <doc:PrivacyConsiderations>
- <doc:CustomProviders>
