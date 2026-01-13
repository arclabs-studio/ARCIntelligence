# ``ARCIntelligence``

Professional AI capabilities for iOS and macOS applications.

## Overview

ARCIntelligence is a Swift package that provides AI-powered features through a clean, protocol-based architecture. It allows you to abstract different AI providers (Apple Foundation Models, OpenAI, Anthropic) behind unified interfaces while maintaining maximum privacy and performance.

The package is built with Swift 6 concurrency in mind, providing full `async/await` support and `Sendable` compliance throughout.

### Key Features

- **Protocol-Based Architecture**: Easily swap AI providers without changing your code
- **Apple Foundation Models**: Privacy-first, on-device AI for iOS 18.0+
- **Conversational AI**: Multi-turn dialogue management with context preservation
- **Recommendations**: Personalized suggestions based on user context
- **Semantic Search**: Vector-based similarity search with embeddings
- **Swift 6 Ready**: Full concurrency support with strict checking
- **Testing Support**: Comprehensive mocks for testing without real API calls
- **Zero Dependencies**: Pure Swift implementation

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:ChoosingAProvider>

### Core Protocols

- ``IntelligenceProvider``
- ``ConversationProvider``
- ``RecommendationProvider``
- ``EmbeddingProvider``

### Providers

- ``FoundationModelsProvider``
- ``FoundationModelsConfiguration``
- ``FoundationModelsCapabilities``

### Use Cases

- ``ConversationalAssistant``
- ``RecommendationEngine``
- ``SemanticSearch``

### Models

- ``Message``
- ``Conversation``
- ``Recommendation``
- ``Embedding``
- ``IntelligenceResponse``
- ``IntelligenceRequest``
- ``CompletionConfiguration``
- ``RecommendationConfiguration``

### Utilities

- ``PromptBuilder``
- ``TokenCounter``

### Error Handling

- ``IntelligenceError``

### Testing

- <doc:Testing>

### Advanced Topics

- <doc:CustomProviders>
- <doc:PrivacyConsiderations>
- <doc:BestPractices>
