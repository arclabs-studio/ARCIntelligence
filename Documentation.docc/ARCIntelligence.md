# ``ARCIntelligence``

Professional AI capabilities for iOS and macOS applications.

## Overview

ARCIntelligence provides AI-powered features through a clean, protocol-based architecture. Abstract different AI providers (Apple Foundation Models, OpenAI, Anthropic) behind unified interfaces with maximum privacy and performance.

The package follows Clean Architecture principles, making it easy to swap AI providers without changing your application code. It fully embraces Swift 6 concurrency with `async/await` and `Sendable` compliance throughout.

### Key Features

- **Protocol-Based Architecture** - Easy to swap AI providers without changing your code
- **Apple Foundation Models** - Privacy-first, on-device AI (iOS 18.0+)
- **Conversational AI** - Multi-turn dialogue management with context preservation
- **Recommendations Engine** - Personalized suggestions based on user context
- **Semantic Search** - Vector-based similarity search with embeddings
- **Swift 6 Concurrency** - Full `async/await` and `Sendable` compliance

## Topics

### Essentials

- <doc:GettingStarted>
- ``ARCIntelligence``

### Core Protocols

- ``IntelligenceProvider``
- ``ConversationProvider``
- ``EmbeddingProvider``
- ``RecommendationProvider``

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
- ``IntelligenceResponse``
- ``IntelligenceRequest``
- ``CompletionConfiguration``
- ``Embedding``
- ``Recommendation``
- ``RecommendationConfiguration``

### Utilities

- ``PromptBuilder``
- ``TokenCounter``

### Errors

- ``IntelligenceError``
