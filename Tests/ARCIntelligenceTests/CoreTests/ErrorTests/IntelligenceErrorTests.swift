//
//  IntelligenceErrorTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Testing
@testable import ARCIntelligence

@Suite("IntelligenceError Tests")
struct IntelligenceErrorTests {
    @Test("Provider unavailable error has correct description")
    func providerUnavailableErrorDescription() {
        let error = IntelligenceError.providerUnavailable
        #expect(error.errorDescription?.contains("not available") == true)
    }

    @Test("Provider not configured error includes name")
    func providerNotConfiguredErrorIncludesName() {
        let providerName = "TestProvider"
        let error = IntelligenceError.providerNotConfigured(providerName)
        #expect(error.errorDescription?.contains(providerName) == true)
    }

    @Test("Invalid request error includes reason")
    func invalidRequestErrorIncludesReason() {
        let reason = "Invalid parameter"
        let error = IntelligenceError.invalidRequest(reason)
        #expect(error.errorDescription?.contains(reason) == true)
    }

    @Test("Token limit exceeded error includes counts")
    func tokenLimitExceededErrorIncludesCounts() {
        let error = IntelligenceError.tokenLimitExceeded(current: 100, max: 50)
        let description = error.errorDescription ?? ""
        #expect(description.contains("100") == true)
        #expect(description.contains("50") == true)
    }
}
