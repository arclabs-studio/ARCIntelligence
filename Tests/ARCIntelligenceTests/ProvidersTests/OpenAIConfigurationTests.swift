//
//  OpenAIConfigurationTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 17/02/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("OpenAI Configuration Tests")
struct OpenAIConfigurationTests {
    // MARK: - Helpers

    private func makeSUT(authentication: OpenAIAuthentication = .apiKey("test-key"),
                         model: OpenAIModel = .gpt4oMini,
                         defaultTemperature: Float = 0.7,
                         defaultMaxTokens: Int = 4096,
                         maxToolRounds: Int = 10) -> OpenAIConfiguration {
        OpenAIConfiguration(authentication: authentication,
                            model: model,
                            defaultTemperature: defaultTemperature,
                            defaultMaxTokens: defaultMaxTokens,
                            maxToolRounds: maxToolRounds)
    }

    // MARK: - Defaults

    @Test("Default configuration uses GPT-4o Mini model")
    func defaultModel() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.model == .gpt4oMini)
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
        #expect(OpenAIModel.gpt4oMini.modelId == "gpt-4o-mini")
        #expect(OpenAIModel.gpt4o.modelId == "gpt-4o")
        #expect(OpenAIModel.o3Mini.modelId == "o3-mini")
        #expect(OpenAIModel.custom("ft:gpt-4o-mini:my-org").modelId == "ft:gpt-4o-mini:my-org")
    }

    // MARK: - Presets

    @Test("Fast preset uses GPT-4o Mini")
    func fastPreset() {
        // Given
        let sut = OpenAIConfiguration.fast(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .gpt4oMini)
        #expect(sut.defaultTemperature == 0.3)
        #expect(sut.defaultMaxTokens == 2048)
    }

    @Test("Balanced preset uses GPT-4o")
    func balancedPreset() {
        // Given
        let sut = OpenAIConfiguration.balanced(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .gpt4o)
        #expect(sut.defaultTemperature == 0.7)
    }

    @Test("Quality preset uses o3-mini")
    func qualityPreset() {
        // Given
        let sut = OpenAIConfiguration.quality(authentication: .apiKey("k"))

        // Then
        #expect(sut.model == .o3Mini)
        #expect(sut.defaultMaxTokens == 8192)
    }

    // MARK: - Authentication

    @Test("API key authentication stores key")
    func apiKeyAuth() {
        // Given
        let auth = OpenAIAuthentication.apiKey("sk-test")

        // Then
        #expect(auth == .apiKey("sk-test"))
    }

    @Test("AIProxy authentication stores both values")
    func aiProxyAuth() {
        // Given
        let auth = OpenAIAuthentication.aiProxy(partialKey: "pk", serviceURL: "https://proxy.test")

        // Then
        #expect(auth == .aiProxy(partialKey: "pk", serviceURL: "https://proxy.test"))
    }

    // MARK: - Organization

    @Test("Organization is stored when provided")
    func organizationStored() {
        // Given
        let sut = OpenAIConfiguration(authentication: .apiKey("k"),
                                      organization: "org-test")

        // Then
        #expect(sut.organization == "org-test")
    }

    @Test("Organization is nil by default")
    func organizationNilByDefault() {
        // Given
        let sut = makeSUT()

        // Then
        #expect(sut.organization == nil)
    }
}
