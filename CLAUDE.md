# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a single test
swift test --filter "TestSuiteName/testMethodName"
# Example: swift test --filter "ConversationalAssistantTests/sendMessageUpdatesConversation"

# Run SwiftLint
swiftlint

# Generate documentation
swift package generate-documentation

# Run the showcase app
cd Examples/ARCIntelligenceShowcase && open Package.swift
```

## Architecture Overview

ARCIntelligence is a Swift 6 package providing AI capabilities through protocol-oriented design.

### Core Layer (`Sources/ARCIntelligence/Core/`)
- **Protocols**: `IntelligenceProvider` (base), `ConversationProvider`, `EmbeddingProvider`, `RecommendationProvider`
- **Models**: Data types for messages, conversations, embeddings, responses, configurations
- **Errors**: `IntelligenceError` enum with `LocalizedError` conformance

### Providers Layer (`Sources/ARCIntelligence/Providers/`)
- Concrete implementations of core protocols
- Currently: `FoundationModelsProvider` for Apple's on-device AI (iOS 18+)

### Use Cases Layer (`Sources/ARCIntelligence/UseCases/`)
- High-level business logic: `ConversationalAssistant`, `RecommendationEngine`, `SemanticSearch`
- Orchestrates providers with domain-specific workflows

### Main API (`ARCIntelligence.swift`)
- Factory methods for creating providers and use cases
- Entry point: `ARCIntelligence.foundationModels()`, `ARCIntelligence.conversationalAssistant(provider:)`

### Mocks (`Sources/ARCIntelligenceMocks/`)
- `MockIntelligenceProvider` and `MockConversationProvider` for testing

## Code Standards

### File Organization
- **One type per file**, file name matches type name
- Required file header:
```swift
//
//  [FileName].swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on [Date].
//
```

### Swift 6 Concurrency
- All public types must conform to `Sendable`
- Use `async/await` for all asynchronous operations
- Use `AsyncThrowingStream` for streaming data
- Strict concurrency checking is enabled via `StrictConcurrency` experimental feature

### Testing
- Use Swift Testing framework (`import Testing`)
- Test naming: `methodName_withCondition()` (e.g., `execute_withSuccess`)
- Use `@Suite("Description")` and `@Test("Description")` annotations
- Import mocks: `import ARCIntelligenceMocks`

### Documentation
- DocC comments required for all public APIs
- Include `- Parameters:`, `- Returns:`, `- Throws:` sections

## Platform Requirements

- Swift 6.0+
- iOS 17.0+ / macOS 14.0+
- Xcode 16.0+
