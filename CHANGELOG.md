# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (breaking)

- **`ResponseFormat.json(schema:)` takes a `JSONValue?` instead of `[String: Any]?`.** `ResponseFormat` is now compiler-checked `Sendable` instead of `@unchecked Sendable`, and its `Equatable` conformance now compares schemas. Before, any two `.json` values compared equal. Build schemas with `JSONValue` cases, for example `.object(["type": .string("ARRAY")])`.
- **`ToolArgumentValue` is renamed `JSONValue`**, since the same type now describes response schemas as well as tool arguments. `ToolArgumentValue` remains as a deprecated typealias, so existing tool code compiles with a warning.

## [1.1.1] - 2026-11-06

### Changed

- **Examples.** The showcase app uses `NavigationStack` instead of `NavigationView` and FormatStyle / `Duration`
  instead of `String(format:)`, and no longer force-unwraps URLs. The demo is now linted in CI.
  ([#29](https://github.com/arclabs-studio/ARCIntelligence/pull/29), [#30](https://github.com/arclabs-studio/ARCIntelligence/pull/30))

### Fixed

- **`ARCIntelligenceMocks` streaming now stops when the consumer stops.** `MockIntelligenceProvider`,
  `MockConversationProvider`, `MockEmbeddingProvider` and `MockRecommendationProvider` cancel their
  producer task from the stream's `onTermination`. Before, the task kept emitting characters in the
  background after the consumer cancelled or stopped iterating. ([#29](https://github.com/arclabs-studio/ARCIntelligence/pull/29))
- **Errors in mock streams now reach the consumer.** If the producer throws (for example
  `CancellationError` from `Task.sleep`), the stream finishes with that error. Before, the
  unhandled task error was dropped and the stream never finished. ([#29](https://github.com/arclabs-studio/ARCIntelligence/pull/29))

## [1.1.0] - 2026-09-20
### Added
- `IntelligenceResponse.tokensIn` / `.tokensOut` — optional, defaulted fields carrying the
  prompt/completion token split when a provider reports it. `tokensUsed` is unchanged and
  still reflects the total. Additive and non-breaking; every existing call site compiles
  unchanged.

## [1.0.0] - 2026-08-20

First public release of **ARCIntelligence**.

ARC Labs Studio re-baselined every package at `1.0.0` for its first product launch. The pre-launch version history (0.1.0 → 1.0.0) never corresponded to a release the studio stood behind; those tags and GitHub Releases have been removed and the notes are preserved below under [Pre-1.0 history](#pre-10-history-untagged).

### Added

- **`INTERNAL-USE.md`** — documents ARC Labs Studio's self-grant for commercial use of its own products under the new licence.

- **Anthropic provider** (`AnthropicProvider`) with full support for completions, streaming,
  tool calling, and generable (structured output) via the Anthropic API
- **OpenAI provider** (`OpenAIProvider`) with support for completions, streaming, tool calling,
  and generable via the OpenAI-compatible API
- **Gemini provider** (`GeminiProvider`) with support for completions, streaming, tool calling,
  and structured output (generable) via the Google Gemini native v1 REST API
  (`generativelanguage.googleapis.com`). Provides resilience redundancy with `ARCFirebaseAI` —
  use both and fall back when Firebase reports model overload
- `GeminiConfiguration` for provider setup with `.fast`, `.balanced`, and `.quality` presets;
  `GeminiAuthentication` and `GeminiModel` enums; `GeminiHTTPClient` and `GeminiStreamParser`
  for native API networking
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

- **ARCNetworking dependency** — converted from a `branch: "develop"` pin to `from: "1.0.0"`. SPM refuses branch requirements in a versioned package, so this package could not be released until the pin was converted.

- `FoundationModelsProvider` refactored to use shared patterns and improved concurrency safety
- Showcase app (`ARCIntelligenceShowcaseApp`) migrated from `ObservableObject` to `@Observable`
- `SettingsView` updated to support multi-provider configuration
- Streaming implementation uses `Task.detached` with `onTermination` for safe stream lifecycle
- `cosineSimilarity` optimised using Accelerate `vDSP` for performance
- `SemanticSearch` and `RecommendationEngine` use `reserveCapacity` for better allocation
- `AnthropicHTTPClient` and `OpenAICompatibleHTTPClient` now default to
  `RetryInterceptor(maxRetries: 2)` + `LoggingInterceptor`, adding automatic exponential-backoff
  retry on transient 5xx errors without changing any public API

- **License** — relicensed from MIT to [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0). Source-available and free for non-commercial use; commercial use requires a separate licence from ARC Labs Studio. ARC Labs Studio's own products are covered by an internal grant — see `INTERNAL-USE.md`.

### Fixed

- Stream capture safety: eliminated data races in `AsyncThrowingStream` continuation captures
- `CancellationError` now propagates correctly through streaming pipelines
- Replaced `fatalError` with safe optional URL initialisation in provider configuration
- StrictConcurrency enabled for `ARCIntelligenceMocks` target

### Tests

- `MockHTTPClient` extended with `streamLinesToReturn` and `streamErrorToThrow` to enable
  full streaming-path coverage without network access
- Added 4 streaming-path tests covering happy path and 401→`authenticationFailed` mapping
  for both `AnthropicHTTPClient.streamMessage` and `OpenAICompatibleHTTPClient.streamChatCompletion`

---

## Pre-1.0 history (untagged)

Everything below predates the 1.0.0 baseline. The version numbers are retained for traceability only — no tag or release exists for any of them.

### [0.1.0] - 2025-01-01

#### Added
- Initial release

---

[1.0.0]: https://github.com/arclabs-studio/ARCIntelligence/releases/tag/v1.0.0
