//
//  GrokConfigurationTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("Grok Configuration Tests")
struct GrokConfigurationTests {
    // MARK: - Helpers

    private func makeSUT(authentication: GrokAuthentication = .apiKey("test-key"),
                         model: GrokModel = .grok3Fast,
                         defaultTemperature: Float = 0.7,
                         defaultMaxTokens: Int = 4096,
                         maxToolRounds: Int = 10) -> GrokConfiguration {
        GrokConfiguration(authentication: authentication,
                          model: model,
                          defaultTemperature: defaultTemperature,
                          defaultMaxTokens: defaultMaxTokens,
                          maxToolRounds: maxToolRounds)
    }

    // MARK: - Defaults

    @Test("Default configuration uses Grok 3 Fast model")
    func defaultModel() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.model == .grok3Fast)
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
        #expect(high.defaultTemperature == 2.0)
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
        #expect(GrokModel.grok3.modelId == "grok-3")
        #expect(GrokModel.grok3Fast.modelId == "grok-3-fast")
        #expect(GrokModel.custom("grok-4-beta").modelId == "grok-4-beta")
    }

    // MARK: - Presets

    @Test("Fast preset uses Grok 3 Fast")
    func fastPreset() {
        // Given
        let sut = GrokConfiguration.fast(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .grok3Fast)
        #expect(sut.defaultTemperature == 0.3)
        #expect(sut.defaultMaxTokens == 2048)
    }

    @Test("Balanced preset uses Grok 3")
    func balancedPreset() {
        // Given
        let sut = GrokConfiguration.balanced(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .grok3)
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Quality preset uses Grok 3")
    func qualityPreset() {
        // Given
        let sut = GrokConfiguration.quality(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .grok3)
        #expect(sut.defaultMaxTokens == 8192)
    }

    // MARK: - Authentication

    @Test("API key authentication stores key")
    func apiKeyAuth() {
        // Given
        let auth = GrokAuthentication.apiKey("xai-test")

        // Then
        #expect(auth == .apiKey("xai-test"))
    }

    @Test("AIProxy authentication stores both values")
    func aiProxyAuth() {
        // Given
        let auth = GrokAuthentication.aiProxy(partialKey: "pk", serviceURL: "https://proxy.test")

        // Then
        #expect(auth == .aiProxy(partialKey: "pk", serviceURL: "https://proxy.test"))
    }
}
