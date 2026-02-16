//
//  MockProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Testing
@testable import ARCIntelligence
@testable import ARCIntelligenceMocks

@Suite("Mock Provider Tests")
struct MockProviderTests {
    @Test("Mock provider is always available")
    func mockProviderIsAvailable() async {
        let provider = MockIntelligenceProvider()
        let available = await provider.isAvailable()
        #expect(available)
    }

    @Test("Mock provider returns configured responses")
    func mockProviderReturnsConfiguredResponses() async throws {
        let expectedResponse = "Test response"
        let provider = MockIntelligenceProvider(responses: [expectedResponse],
                                                shouldFail: false)

        let response = try await provider.complete(prompt: "Test",
                                                   configuration: .default)

        #expect(response.content == expectedResponse)
    }

    @Test("Mock provider throws error when configured to fail")
    func mockProviderThrowsErrorWhenConfiguredToFail() async {
        let provider = MockIntelligenceProvider(shouldFail: true)

        await #expect(throws: IntelligenceError.self) {
            try await provider.complete(prompt: "Test",
                                        configuration: .default)
        }
    }

    @Test("Mock provider streams responses")
    func mockProviderStreamsResponses() async throws {
        let expectedResponse = "Stream"
        let provider = MockIntelligenceProvider(responses: [expectedResponse],
                                                simulatedDelay: 0.01)

        var streamedContent = ""
        for try await chunk in provider.streamComplete(prompt: "Test",
                                                       configuration: .default) {
            streamedContent += chunk
        }

        #expect(streamedContent == expectedResponse)
    }
}
