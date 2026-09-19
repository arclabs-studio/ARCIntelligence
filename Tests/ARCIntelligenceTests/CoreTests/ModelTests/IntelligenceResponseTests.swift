//
//  IntelligenceResponseTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import Testing
@testable import ARCIntelligence

@Suite("IntelligenceResponse Tests", .tags(.unit)) struct IntelligenceResponseTests {
    @Test("Initializes with default token split values") func initializesWithDefaults() {
        let response = IntelligenceResponse(content: "Hello", tokensUsed: 42)

        #expect(response.tokensUsed == 42)
        #expect(response.tokensIn == nil)
        #expect(response.tokensOut == nil)
    }

    @Test("Initializes with explicit token split values") func initializesWithCustomValues() {
        let response = IntelligenceResponse(content: "Hello",
                                            tokensUsed: 42,
                                            tokensIn: 30,
                                            tokensOut: 12)

        #expect(response.tokensUsed == 42)
        #expect(response.tokensIn == 30)
        #expect(response.tokensOut == 12)
    }
}
