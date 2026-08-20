//
//  GeminiConfigurationTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 13/04/2026.
//

import Testing
@testable import ARCIntelligence

@Suite(.tags(.unit)) struct GeminiConfigurationTests {
    // MARK: - Helpers

    private func makeSUT(authentication: GeminiAuthentication = .apiKey("test-key"),
                         model: GeminiModel = .gemini2Flash,
                         defaultTemperature: Float = 0.7,
                         defaultMaxTokens: Int = 4096,
                         maxToolRounds: Int = 10) -> GeminiConfiguration {
        GeminiConfiguration(authentication: authentication,
                            model: model,
                            defaultTemperature: defaultTemperature,
                            defaultMaxTokens: defaultMaxTokens,
                            maxToolRounds: maxToolRounds)
    }

    // MARK: - Defaults

    @Test("Default configuration uses Gemini 2.0 Flash") func defaultModel() {
        let sut = makeSUT()
        #expect(sut.model == .gemini2Flash)
    }

    @Test("Default configuration has standard temperature") func defaultTemperature() {
        let sut = makeSUT()
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Default configuration has 4096 max tokens") func defaultMaxTokens() {
        let sut = makeSUT()
        #expect(sut.defaultMaxTokens == 4096)
    }

    // MARK: - Clamping

    @Test("Temperature is clamped to valid range 0.0-2.0") func temperatureClamping() {
        let low = makeSUT(defaultTemperature: -1.0)
        let high = makeSUT(defaultTemperature: 5.0)

        #expect(low.defaultTemperature == 0.0)
        #expect(high.defaultTemperature == 2.0)
    }

    @Test("Max tokens is clamped to valid range 1-8192") func maxTokensClamping() {
        let low = makeSUT(defaultMaxTokens: 0)
        let high = makeSUT(defaultMaxTokens: 999_999)

        #expect(low.defaultMaxTokens == 1)
        #expect(high.defaultMaxTokens == 8192)
    }

    @Test("Max tool rounds is clamped to valid range") func maxToolRoundsClamping() {
        let low = makeSUT(maxToolRounds: 0)
        let high = makeSUT(maxToolRounds: 100)

        #expect(low.maxToolRounds == 1)
        #expect(high.maxToolRounds == 50)
    }

    // MARK: - Model IDs

    @Test("Model enum returns correct model IDs") func modelIds() {
        #expect(GeminiModel.gemini2Flash.modelId == "gemini-2.0-flash")
        #expect(GeminiModel.gemini2FlashLite.modelId == "gemini-2.0-flash-lite")
        #expect(GeminiModel.gemini15Pro.modelId == "gemini-1.5-pro")
        #expect(GeminiModel.gemini15Flash.modelId == "gemini-1.5-flash")
        #expect(GeminiModel.custom("gemini-exp-1206").modelId == "gemini-exp-1206")
    }

    // MARK: - Presets

    @Test("Fast preset uses Gemini 2.0 Flash-Lite") func fastPreset() {
        let sut = GeminiConfiguration.fast(authentication: .apiKey("k"))

        #expect(sut.model == .gemini2FlashLite)
        #expect(sut.defaultTemperature == 0.3)
        #expect(sut.defaultMaxTokens == 2048)
    }

    @Test("Balanced preset uses Gemini 2.0 Flash") func balancedPreset() {
        let sut = GeminiConfiguration.balanced(authentication: .apiKey("k"))

        #expect(sut.model == .gemini2Flash)
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Quality preset uses Gemini 1.5 Pro") func qualityPreset() {
        let sut = GeminiConfiguration.quality(authentication: .apiKey("k"))

        #expect(sut.model == .gemini15Pro)
        #expect(sut.defaultMaxTokens == 8192)
    }

    // MARK: - Authentication

    @Test("API key authentication stores key") func apiKeyAuth() {
        let auth = GeminiAuthentication.apiKey("AIza-test")
        #expect(auth == .apiKey("AIza-test"))
    }

    @Test("AIProxy authentication stores both values") func aiProxyAuth() {
        let auth = GeminiAuthentication.aiProxy(partialKey: "pk", serviceURL: "https://proxy.test")
        #expect(auth == .aiProxy(partialKey: "pk", serviceURL: "https://proxy.test"))
    }
}
