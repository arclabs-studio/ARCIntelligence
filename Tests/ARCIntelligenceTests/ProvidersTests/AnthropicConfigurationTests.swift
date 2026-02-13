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
    // MARK: - Defaults

    @Test("Default configuration uses Sonnet model")
    func defaultModel() {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"))
        #expect(config.model == .sonnet)
    }

    @Test("Default configuration has standard temperature")
    func defaultTemperature() {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"))
        #expect(config.defaultTemperature == 0.7)
    }

    @Test("Default configuration has 4096 max tokens")
    func defaultMaxTokens() {
        let config = AnthropicConfiguration(authentication: .apiKey("test-key"))
        #expect(config.defaultMaxTokens == 4096)
    }

    // MARK: - Clamping

    @Test("Temperature is clamped to valid range")
    func temperatureClamping() {
        let low = AnthropicConfiguration(authentication: .apiKey("k"), defaultTemperature: -1.0)
        let high = AnthropicConfiguration(authentication: .apiKey("k"), defaultTemperature: 5.0)
        #expect(low.defaultTemperature == 0.0)
        #expect(high.defaultTemperature == 1.0)
    }

    @Test("Max tokens is clamped to valid range")
    func maxTokensClamping() {
        let low = AnthropicConfiguration(authentication: .apiKey("k"), defaultMaxTokens: 0)
        let high = AnthropicConfiguration(authentication: .apiKey("k"), defaultMaxTokens: 999_999)
        #expect(low.defaultMaxTokens == 1)
        #expect(high.defaultMaxTokens == 128_000)
    }

    @Test("Max tool rounds is clamped to valid range")
    func maxToolRoundsClamping() {
        let low = AnthropicConfiguration(authentication: .apiKey("k"), maxToolRounds: 0)
        let high = AnthropicConfiguration(authentication: .apiKey("k"), maxToolRounds: 100)
        #expect(low.maxToolRounds == 1)
        #expect(high.maxToolRounds == 50)
    }

    // MARK: - Model IDs

    @Test("Model enum returns correct model IDs")
    func modelIds() {
        #expect(AnthropicModel.haiku.modelId == "claude-3-5-haiku-latest")
        #expect(AnthropicModel.sonnet.modelId == "claude-sonnet-4-5-20250929")
        #expect(AnthropicModel.opus.modelId == "claude-opus-4-6")
        #expect(AnthropicModel.custom("my-model").modelId == "my-model")
    }

    // MARK: - Presets

    @Test("Fast preset uses Haiku")
    func fastPreset() {
        let config = AnthropicConfiguration.fast(authentication: .apiKey("k"))
        #expect(config.model == .haiku)
        #expect(config.defaultTemperature == 0.3)
        #expect(config.defaultMaxTokens == 2048)
    }

    @Test("Balanced preset uses Sonnet")
    func balancedPreset() {
        let config = AnthropicConfiguration.balanced(authentication: .apiKey("k"))
        #expect(config.model == .sonnet)
        #expect(config.defaultTemperature == 0.7)
    }

    @Test("Quality preset uses Opus")
    func qualityPreset() {
        let config = AnthropicConfiguration.quality(authentication: .apiKey("k"))
        #expect(config.model == .opus)
        #expect(config.defaultMaxTokens == 8192)
    }

    // MARK: - Authentication

    @Test("API key authentication stores key")
    func apiKeyAuth() {
        let auth = AnthropicAuthentication.apiKey("sk-ant-test")
        #expect(auth == .apiKey("sk-ant-test"))
    }

    @Test("AIProxy authentication stores both values")
    func aiProxyAuth() {
        let auth = AnthropicAuthentication.aiProxy(partialKey: "pk", serviceURL: "https://proxy.test")
        #expect(auth == .aiProxy(partialKey: "pk", serviceURL: "https://proxy.test"))
    }
}
