# Creating Custom Providers

Learn how to create your own AI provider implementations.

## Overview

ARCIntelligence's protocol-based architecture makes it easy to add support for new AI providers. This guide shows you how to create a custom provider that integrates seamlessly with the rest of the package.

## Implementing IntelligenceProvider

The basic provider protocol requires these methods:

```swift
import Foundation
import ARCIntelligence

public final class MyCustomProvider: IntelligenceProvider, Sendable {

    // MARK: - Properties

    public let id = "com.mycompany.custom"
    public let displayName = "My Custom Provider"
    public let version = "1.0.0"

    private let apiKey: String
    private let endpoint: URL

    // MARK: - Initialization

    public init(apiKey: String, endpoint: URL) {
        self.apiKey = apiKey
        self.endpoint = endpoint
    }

    // MARK: - IntelligenceProvider

    public func isAvailable() async -> Bool {
        // Check if the provider can be used
        // For example, verify API key, check network connectivity, etc.
        return !apiKey.isEmpty
    }

    public func complete(
        prompt: String,
        configuration: CompletionConfiguration
    ) async throws -> IntelligenceResponse {
        guard await isAvailable() else {
            throw IntelligenceError.providerUnavailable
        }

        // Build request
        let request = buildRequest(prompt: prompt, configuration: configuration)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IntelligenceError.requestFailed("HTTP error")
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

        return IntelligenceResponse(
            content: apiResponse.text,
            tokensUsed: apiResponse.tokensUsed,
            finishReason: .completed,
            metadata: ["model": apiResponse.model]
        )
    }

    public func streamComplete(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard await isAvailable() else {
                        throw IntelligenceError.providerUnavailable
                    }

                    let request = buildStreamRequest(prompt: prompt, configuration: configuration)

                    // Stream response
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw IntelligenceError.requestFailed("HTTP error")
                    }

                    for try await line in bytes.lines {
                        // Parse SSE format
                        if let chunk = parseSSELine(line) {
                            continuation.yield(chunk)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": configuration.temperature,
            "max_tokens": configuration.maxTokens ?? 1024
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return request
    }

    private func buildStreamRequest(
        prompt: String,
        configuration: CompletionConfiguration
    ) -> URLRequest {
        var request = buildRequest(prompt: prompt, configuration: configuration)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        return request
    }

    private func parseSSELine(_ line: String) -> String? {
        // Parse Server-Sent Events format
        guard line.hasPrefix("data: ") else { return nil }
        return String(line.dropFirst(6))
    }
}

// MARK: - Supporting Types

private struct APIResponse: Codable {
    let text: String
    let tokensUsed: Int
    let model: String

    enum CodingKeys: String, CodingKey {
        case text
        case tokensUsed = "tokens_used"
        case model
    }
}
```

## Adding Conversation Support

Extend your provider to support conversations:

```swift
extension MyCustomProvider: ConversationProvider {

    public func sendMessage(
        _ message: Message,
        in conversation: Conversation
    ) async throws -> Message {
        // Build a prompt that includes conversation history
        let fullPrompt = buildConversationPrompt(
            conversation: conversation,
            newMessage: message
        )

        // Use the base completion method
        let response = try await complete(
            prompt: fullPrompt,
            configuration: CompletionConfiguration(
                temperature: 0.7,
                systemPrompt: conversation.systemPrompt
            )
        )

        return Message(
            role: .assistant,
            content: response.content,
            metadata: [
                "tokens": "\(response.tokensUsed)",
                "provider": id
            ]
        )
    }

    public func continueConversation(
        _ conversation: Conversation,
        with text: String
    ) async throws -> Message {
        let userMessage = Message(role: .user, content: text)
        return try await sendMessage(userMessage, in: conversation)
    }

    public func estimateTokens(for conversation: Conversation) -> Int {
        let counter = TokenCounter()
        return counter.estimateTokens(for: conversation)
    }

    // MARK: - Private Helpers

    private func buildConversationPrompt(
        conversation: Conversation,
        newMessage: Message
    ) -> String {
        var prompt = ""

        // Add system prompt if present
        if let systemPrompt = conversation.systemPrompt {
            prompt += "System: \(systemPrompt)\n\n"
        }

        // Add message history
        for message in conversation.messages {
            let roleLabel = message.role.rawValue.capitalized
            prompt += "\(roleLabel): \(message.content)\n"
        }

        // Add new message
        prompt += "User: \(newMessage.content)\nAssistant:"

        return prompt
    }
}
```

## Adding Recommendation Support

Implement recommendation capabilities:

```swift
extension MyCustomProvider: RecommendationProvider {

    public func generateRecommendations<T: Codable & Sendable>(
        for context: T,
        count: Int,
        configuration: RecommendationConfiguration
    ) async throws -> [Recommendation] {
        // Serialize context to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let contextData = try encoder.encode(context)
        let contextJSON = String(data: contextData, encoding: .utf8) ?? "{}"

        // Build recommendation prompt
        let prompt = """
        Based on this context:
        \(contextJSON)

        Generate \(count) recommendations with diversity factor \(configuration.diversity).
        Return JSON array with: title, description, confidence (0.0-1.0), category.
        """

        // Get completion
        let response = try await complete(
            prompt: prompt,
            configuration: CompletionConfiguration(
                temperature: Float(configuration.diversity),
                maxTokens: 2048
            )
        )

        // Parse recommendations from response
        return try parseRecommendations(from: response.content, count: count)
    }

    private func parseRecommendations(from content: String, count: Int) throws -> [Recommendation] {
        // Parse JSON response
        guard let data = content.data(using: .utf8) else {
            throw IntelligenceError.responseParseFailed("Invalid UTF-8")
        }

        struct RecommendationDTO: Codable {
            let title: String
            let description: String
            let confidence: Float
            let category: String?
        }

        let recommendations = try JSONDecoder().decode([RecommendationDTO].self, from: data)

        return recommendations.prefix(count).map { dto in
            Recommendation(
                title: dto.title,
                description: dto.description,
                confidence: dto.confidence,
                category: dto.category
            )
        }
    }
}
```

## Adding Embedding Support

Implement semantic embedding generation:

```swift
extension MyCustomProvider: EmbeddingProvider {

    public func generateEmbedding(for text: String) async throws -> Embedding {
        guard await isAvailable() else {
            throw IntelligenceError.providerUnavailable
        }

        // Build embedding request
        var request = URLRequest(url: endpoint.appendingPathComponent("/embeddings"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw IntelligenceError.requestFailed("Embedding request failed")
        }

        // Parse response
        struct EmbeddingResponse: Codable {
            let embedding: [Float]
        }

        let embeddingResponse = try JSONDecoder().decode(EmbeddingResponse.self, from: data)

        return Embedding(
            vector: embeddingResponse.embedding,
            text: text
        )
    }

    public func similarity(between text1: String, and text2: String) async throws -> Float {
        let embedding1 = try await generateEmbedding(for: text1)
        let embedding2 = try await generateEmbedding(for: text2)

        return embedding1.cosineSimilarity(to: embedding2)
    }

    public func generateEmbeddings(for texts: [String]) async throws -> [Embedding] {
        // Generate embeddings concurrently
        try await withThrowingTaskGroup(of: (Int, Embedding).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let embedding = try await self.generateEmbedding(for: text)
                    return (index, embedding)
                }
            }

            var embeddings: [(Int, Embedding)] = []
            for try await result in group {
                embeddings.append(result)
            }

            // Sort by original index to maintain order
            return embeddings.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}
```

## Configuration Pattern

Provide a configuration type for your provider:

```swift
public struct MyCustomProviderConfiguration: Sendable, Equatable {

    // MARK: - Properties

    public let apiKey: String
    public let endpoint: URL
    public let defaultTimeout: TimeInterval
    public let maxRetries: Int

    // MARK: - Initialization

    public init(
        apiKey: String,
        endpoint: URL = URL(string: "https://api.example.com/v1")!,
        defaultTimeout: TimeInterval = 30.0,
        maxRetries: Int = 3
    ) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.defaultTimeout = defaultTimeout
        self.maxRetries = max(0, maxRetries)
    }

    // MARK: - Validation

    public var isValid: Bool {
        !apiKey.isEmpty && !endpoint.absoluteString.isEmpty
    }
}

// Update provider to use configuration
extension MyCustomProvider {
    public convenience init(configuration: MyCustomProviderConfiguration) {
        self.init(
            apiKey: configuration.apiKey,
            endpoint: configuration.endpoint
        )
    }
}
```

## Testing Your Provider

Create comprehensive tests:

```swift
import Testing
@testable import MyCustomProvider

@Suite("My Custom Provider Tests")
struct MyCustomProviderTests {

    @Test("Provider initializes correctly")
    func providerInitializesCorrectly() {
        let config = MyCustomProviderConfiguration(
            apiKey: "test-key",
            endpoint: URL(string: "https://api.test.com")!
        )

        let provider = MyCustomProvider(configuration: config)

        #expect(provider.id == "com.mycompany.custom")
        #expect(provider.displayName == "My Custom Provider")
    }

    @Test("Provider checks availability")
    func providerChecksAvailability() async {
        let config = MyCustomProviderConfiguration(
            apiKey: "test-key",
            endpoint: URL(string: "https://api.test.com")!
        )

        let provider = MyCustomProvider(configuration: config)
        let available = await provider.isAvailable()

        #expect(available == true)
    }

    // Add more tests for completions, streaming, conversations, etc.
}
```

## Best Practices

### 1. Thread Safety

Ensure your provider is `Sendable`:

```swift
public final class MyProvider: IntelligenceProvider, Sendable {
    // Use immutable properties or actors for mutable state
    private let configuration: Configuration  // ✅ Immutable

    private var cache: [String: String] = [:]  // ❌ Mutable, not thread-safe

    // Instead use actor for mutable state:
    private let cache: CacheActor  // ✅ Thread-safe via actor
}

actor CacheActor {
    private var cache: [String: String] = [:]

    func get(_ key: String) -> String? {
        cache[key]
    }

    func set(_ key: String, value: String) {
        cache[key] = value
    }
}
```

### 2. Error Handling

Map provider-specific errors to `IntelligenceError`:

```swift
private func handleAPIError(_ statusCode: Int) throws {
    switch statusCode {
    case 401:
        throw IntelligenceError.authenticationFailed
    case 429:
        throw IntelligenceError.rateLimitExceeded
    case 500...599:
        throw IntelligenceError.requestFailed("Server error: \(statusCode)")
    default:
        throw IntelligenceError.requestFailed("HTTP \(statusCode)")
    }
}
```

### 3. Resource Management

Clean up resources properly:

```swift
public final class MyProvider: IntelligenceProvider, Sendable {
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: config)
    }

    deinit {
        session.invalidateAndCancel()
    }
}
```

### 4. Documentation

Document your provider thoroughly:

```swift
/// Custom AI provider for MyCompany's API.
///
/// This provider connects to MyCompany's AI service and requires an API key.
///
/// ## Usage
///
/// ```swift
/// let config = MyCustomProviderConfiguration(apiKey: "your-key")
/// let provider = MyCustomProvider(configuration: config)
///
/// let response = try await provider.complete(
///     prompt: "Hello",
///     configuration: .default
/// )
/// ```
///
/// ## Requirements
///
/// - API key from MyCompany
/// - Network connectivity
/// - iOS 17.0+ or macOS 14.0+
public final class MyCustomProvider: IntelligenceProvider, Sendable {
    // Implementation
}
```

## See Also

- <doc:Architecture>
- <doc:BestPractices>
- ``IntelligenceProvider``
- ``ConversationProvider``
- ``RecommendationProvider``
- ``EmbeddingProvider``
