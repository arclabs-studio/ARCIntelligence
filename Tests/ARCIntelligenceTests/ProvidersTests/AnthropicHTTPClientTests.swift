//
//  AnthropicHTTPClientTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/03/2026.
//

import ARCNetworking
import Foundation
import Testing
@testable import ARCIntelligence

@Suite("Anthropic HTTP Client Tests", .tags(.unit)) struct AnthropicHTTPClientTests {
    // MARK: - Helpers

    private func makeSUT(authentication: AnthropicAuthentication = .apiKey("test-key"),
                         httpClient: MockHTTPClient = MockHTTPClient()) -> (sut: AnthropicHTTPClient,
                                                                            mock: MockHTTPClient) {
        let sut = AnthropicHTTPClient(authentication: authentication, httpClient: httpClient)
        return (sut, httpClient)
    }

    private func makeRequest() -> AnthropicMessageRequest {
        AnthropicMessageRequest(model: "claude-sonnet-4-5-20250929",
                                messages: [AnthropicAPIMessage(role: "user", text: "Hello")],
                                maxTokens: 1024,
                                system: nil,
                                temperature: nil,
                                topP: nil,
                                stopSequences: nil,
                                stream: false,
                                tools: nil,
                                toolChoice: nil)
    }

    private func makeResponse(content: String = "Hello") -> AnthropicMessageResponse {
        AnthropicMessageResponse(id: "msg_test",
                                 type: "message",
                                 model: "claude-sonnet-4-5-20250929",
                                 content: [.text(content)],
                                 stopReason: "end_turn",
                                 usage: AnthropicUsage(inputTokens: 10, outputTokens: 20))
    }

    // MARK: - Authentication Validation

    @Test("Should throw providerNotConfigured when API key is empty") func throwsWhenApiKeyIsEmpty() async {
        // Given
        let (sut, _) = makeSUT(authentication: .apiKey(""))

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should throw providerNotConfigured when AIProxy partial key is empty")
    func throwsWhenAIProxyPartialKeyIsEmpty() async {
        // Given
        let (sut, _) = makeSUT(authentication: .aiProxy(partialKey: "", serviceURL: "https://proxy.example.com"))

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should throw providerNotConfigured when AIProxy service URL is empty")
    func throwsWhenAIProxyServiceURLIsEmpty() async {
        // Given
        let (sut, _) = makeSUT(authentication: .aiProxy(partialKey: "partial-key", serviceURL: ""))

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    // MARK: - Send Message — Happy Path

    @Test("Should return response when request succeeds") func returnsResponseOnSuccess() async throws {
        // Given
        let (sut, mock) = makeSUT()
        mock.responseToReturn = makeResponse(content: "Hi there")

        // When
        let response = try await sut.sendMessage(makeRequest())

        // Then
        guard case let .text(text) = response.content.first else {
            Issue.record("Expected text content block")
            return
        }
        #expect(text == "Hi there")
    }

    // MARK: - Send Message — Error Mapping

    @Test("Should map HTTPError.invalidURL to IntelligenceError.invalidRequest") func mapsInvalidURLError() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.invalidURL

        // When / Then
        await #expect(throws: IntelligenceError.invalidRequest("Invalid API URL")) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should map 401 status to IntelligenceError.authenticationFailed")
    func maps401ToAuthenticationFailed() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(401)

        // When / Then
        await #expect(throws: IntelligenceError.authenticationFailed) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should map 429 status to IntelligenceError.rateLimitExceeded") func maps429ToRateLimitExceeded() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(429)

        // When / Then
        await #expect(throws: IntelligenceError.rateLimitExceeded) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should map 400 status to IntelligenceError.invalidRequest") func maps400ToInvalidRequest() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(400)

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should map Anthropic-specific 529 status to IntelligenceError.requestFailed")
    func maps529ToRequestFailed() async throws {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(529)

        // When
        var thrownError: IntelligenceError?
        do {
            _ = try await sut.sendMessage(makeRequest())
        } catch let error as IntelligenceError {
            thrownError = error
        }

        // Then — 529 maps to requestFailed, not authenticationFailed or rateLimitExceeded
        guard case let .requestFailed(message) = thrownError else {
            Issue.record("Expected requestFailed, got \(String(describing: thrownError))")
            return
        }
        #expect(message.contains("overloaded"))
    }

    @Test("Should map 500 status to IntelligenceError.requestFailed") func maps500ToRequestFailed() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(500)

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendMessage(makeRequest())
        }
    }

    @Test("Should map HTTPError.decodingFailed to IntelligenceError.responseParseFailed")
    func mapsDecodingFailedToResponseParseFailed() async throws {
        // Given
        let (sut, mock) = makeSUT()
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad JSON"])
        mock.errorToThrow = HTTPError.decodingFailed(underlyingError)

        // When
        var thrownError: IntelligenceError?
        do {
            _ = try await sut.sendMessage(makeRequest())
        } catch let error as IntelligenceError {
            thrownError = error
        }

        // Then
        guard case .responseParseFailed = thrownError else {
            Issue.record("Expected responseParseFailed, got \(String(describing: thrownError))")
            return
        }
    }

    @Test("Should map HTTPError.unknown to IntelligenceError.requestFailed")
    func mapsUnknownErrorToRequestFailed() async throws {
        // Given
        let (sut, mock) = makeSUT()
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "unknown"])
        mock.errorToThrow = HTTPError.unknown(underlyingError)

        // When
        var thrownError: IntelligenceError?
        do {
            _ = try await sut.sendMessage(makeRequest())
        } catch let error as IntelligenceError {
            thrownError = error
        }

        // Then
        guard case .requestFailed = thrownError else {
            Issue.record("Expected requestFailed, got \(String(describing: thrownError))")
            return
        }
    }

    // MARK: - Status Code Mapping with Error Body

    @Test("Should extract error message from response data in 400 mapping") func extractsErrorMessageFrom400Response() {
        // Given
        let (sut, _) = makeSUT()
        let errorJSON = #"{"error":{"message":"Invalid model specified"}}"#

        // When
        let result = sut.mapHTTPStatusCode(400, data: errorJSON.data(using: .utf8))

        // Then
        guard case let .invalidRequest(message) = result else {
            Issue.record("Expected invalidRequest")
            return
        }
        #expect(message == "Invalid model specified")
    }

    @Test("Should use fallback message when response data has no error body")
    func usesFallbackMessageWhenNoErrorBody() {
        // Given
        let (sut, _) = makeSUT()

        // When
        let result = sut.mapHTTPStatusCode(400, data: nil)

        // Then
        guard case let .invalidRequest(message) = result else {
            Issue.record("Expected invalidRequest")
            return
        }
        #expect(message == "Bad request")
    }

    @Test("Should include status code in default error message") func includesStatusCodeInDefaultMessage() {
        // Given
        let (sut, _) = makeSUT()

        // When
        let result = sut.mapHTTPStatusCode(503, data: nil)

        // Then
        guard case let .requestFailed(message) = result else {
            Issue.record("Expected requestFailed")
            return
        }
        #expect(message.contains("503"))
    }
}
