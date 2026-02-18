//
//  UtilitiesTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import Testing
@testable import ARCIntelligence

@Suite("PromptBuilder Tests", .tags(.unit))
struct PromptBuilderTests {
    @Test("Build simple prompt")
    func buildSimplePrompt() {
        let prompt = PromptBuilder.simple(query: "What is AI?")
        #expect(prompt.contains("What is AI?"))
    }

    @Test("Build prompt with context")
    func buildPromptWithContext() {
        let prompt = PromptBuilder.withContext(query: "Summarize",
                                               context: "Some context")

        #expect(prompt.contains("Summarize"))
        #expect(prompt.contains("Some context"))
    }

    @Test("Build prompt with system instruction")
    func buildPromptWithSystemInstruction() {
        let prompt = PromptBuilder.withSystem(query: "Help me",
                                              systemInstruction: "Be helpful")

        #expect(prompt.contains("Help me"))
        #expect(prompt.contains("Be helpful"))
    }

    @Test("Build custom prompt")
    func buildCustomPrompt() {
        let prompt = PromptBuilder()
            .withSystemInstruction("System")
            .withContext("Context")
            .withQuery("Query")
            .build()

        #expect(prompt.contains("System"))
        #expect(prompt.contains("Context"))
        #expect(prompt.contains("Query"))
    }
}

@Suite("TokenCounter Tests", .tags(.unit))
struct TokenCounterTests {
    @Test("Estimate tokens for text")
    func estimateTokensForText() {
        let counter = TokenCounter()
        let text = "This is a test"
        let tokens = counter.estimateTokens(for: text)

        #expect(tokens > 0)
        #expect(tokens >= text.count / 4)
    }

    @Test("Estimate tokens for multiple texts")
    func estimateTokensForMultipleTexts() {
        let counter = TokenCounter()
        let texts = ["First", "Second", "Third"]
        let tokens = counter.estimateTokens(for: texts)

        #expect(tokens > 0)
    }

    @Test("Check if text fits within limit")
    func checkTextFitsWithinLimit() {
        let counter = TokenCounter()
        let shortText = "Hi"
        let longText = String(repeating: "a", count: 10000)

        #expect(counter.fitsWithinLimit(shortText, limit: 100))
        #expect(!counter.fitsWithinLimit(longText, limit: 10))
    }

    @Test("Truncate text to fit limit")
    func truncateTextToFitLimit() {
        let counter = TokenCounter()
        let longText = String(repeating: "a", count: 1000)
        let truncated = counter.truncate(longText, toLimit: 10)

        #expect(truncated.count < longText.count)
        #expect(truncated.hasSuffix("..."))
    }

    @Test("Static estimate method works")
    func staticEstimateWorks() {
        let tokens = TokenCounter.estimate("Test text")
        #expect(tokens > 0)
    }
}
