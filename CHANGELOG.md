# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Anthropic provider** (`AnthropicProvider`) with full support for completions, streaming,
  tool calling, and generable (structured output) via the Anthropic API
- **OpenAI provider** (`OpenAIProvider`) with support for completions, streaming, tool calling,
  and generable via the OpenAI-compatible API
- **Grok provider** (`GrokProvider`) with support for completions, streaming, tool calling,
  and generable via the xAI Grok API
- **`ToolArgumentValue`** type replacing `[String: Any]` in the tool protocol for type-safe
  tool argument passing with Sendable conformance
- `AnthropicConfiguration`, `OpenAIConfiguration`, `GrokConfiguration` for provider setup
- `OpenAICompatibleHTTPClient` and `OpenAICompatibleStreamParser` shared by OpenAI and Grok
- `AnthropicHTTPClient` and `AnthropicStreamParser` for Anthropic-specific networking
- Comprehensive test suites for all new providers (Anthropic, OpenAI, Grok) including
  configuration, generable, tools, and streaming scenarios
- `.tags(.unit)` added to all existing test suites for test filtering support
- `TestTags.swift` helper defining shared tag constants

### Changed
- `FoundationModelsProvider` refactored to use shared patterns and improved concurrency safety
- Showcase app (`ARCIntelligenceShowcaseApp`) migrated from `ObservableObject` to `@Observable`
- `SettingsView` updated to support multi-provider configuration
- Streaming implementation uses `Task.detached` with `onTermination` for safe stream lifecycle
- `cosineSimilarity` optimised using Accelerate `vDSP` for performance
- `SemanticSearch` and `RecommendationEngine` use `reserveCapacity` for better allocation

### Fixed
- Stream capture safety: eliminated data races in `AsyncThrowingStream` continuation captures
- `CancellationError` now propagates correctly through streaming pipelines
- Replaced `fatalError` with safe optional URL initialisation in provider configuration
- StrictConcurrency enabled for `ARCIntelligenceMocks` target

## [0.1.0] - 2025-01-01

### Added
- Initial release
