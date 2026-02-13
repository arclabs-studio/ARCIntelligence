//
//  AnthropicConfigurationTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Anthropic Configuration Tests")
struct AnthropicConfigurationTests {
    // MARK: - Helpers

    private func makeSUT(
        authentication: AnthropicAuthentication = .apiKey("test-key"),
        model: AnthropicModel = .sonnet,
        defaultTemperature: Float = 0.7,
        defaultMaxTokens: Int = 4096,
        maxToolRounds: Int = 10
    ) -> AnthropicConfiguration {
        AnthropicConfiguration(
            authentication: authentication,
            model: model,
            defaultTemperature: defaultTemperature,
            defaultMaxTokens: defaultMaxTokens,
            maxToolRounds: maxToolRounds
        )
    }

    // MARK: - Defaults

    @Test("Default configuration uses Sonnet model")
    func defaultModel() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.model == .sonnet)
    }

    @Test("Default configuration has standard temperature")
    func defaultTemperature() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Default configuration has 4096 max tokens")
    func defaultMaxTokens() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.defaultMaxTokens == 4096)
    }

    // MARK: - Clamping

    @Test("Temperature is clamped to valid range")
    func temperatureClamping() {
        // Given
        let low = makeSUT(defaultTemperature: -1.0)
        let high = makeSUT(defaultTemperature: 5.0)

        // Then
        #expect(low.defaultTemperature == 0.0)
        #expect(high.defaultTemperature == 1.0)
    }

    @Test("Max tokens is clamped to valid range")
    func maxTokensClamping() {
        // Given
        let low = makeSUT(defaultMaxTokens: 0)
        let high = makeSUT(defaultMaxTokens: 999_999)

        // Then
        #expect(low.defaultMaxTokens == 1)
        #expect(high.defaultMaxTokens == 128_000)
    }

    @Test("Max tool rounds is clamped to valid range")
    func maxToolRoundsClamping() {
        // Given
        let low = makeSUT(maxToolRounds: 0)
        let high = makeSUT(maxToolRounds: 100)

        // Then
        #expect(low.maxToolRounds == 1)
        #expect(high.maxToolRounds == 50)
    }

    // MARK: - Model IDs

    @Test("Model enum returns correct model IDs")
    func modelIds() {
        // Then
        #expect(AnthropicModel.haiku.modelId == "claude-3-5-haiku-latest")
        #expect(AnthropicModel.sonnet.modelId == "claude-sonnet-4-5-20250929")
        #expect(AnthropicModel.opus.modelId == "claude-opus-4-6")
        #expect(AnthropicModel.custom("my-model").modelId == "my-model")
    }

    // MARK: - Presets

    @Test("Fast preset uses Haiku")
    func fastPreset() {
        // Given
        let sut = AnthropicConfiguration.fast(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .haiku)
        #expect(sut.defaultTemperature == 0.3)
        #expect(sut.defaultMaxTokens == 2048)
    }

    @Test("Balanced preset uses Sonnet")
    func balancedPreset() {
        // Given
        let sut = AnthropicConfiguration.balanced(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .sonnet)
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Quality preset uses Opus")
    func qualityPreset() {
        // Given
        let sut = AnthropicConfiguration.quality(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .opus)
        #expect(sut.defaultMaxTokens == 8192)
    }

    // MARK: - Authentication

    @Test("API key authentication stores key")
    func apiKeyAuth() {
        // Given
        let auth = AnthropicAuthentication.apiKey("sk-ant-test")

        // Then
        #expect(auth == .apiKey("sk-ant-test"))
    }

    @Test("AIProxy authentication stores both values")
    func aiProxyAuth() {
        // Given
        let auth = AnthropicAuthentication.aiProxy(partialKey: "pk", serviceURL: "https://proxy.test")

        // Then
        #expect(auth == .aiProxy(partialKey: "pk", serviceURL: "https://proxy.test"))
    }
}
