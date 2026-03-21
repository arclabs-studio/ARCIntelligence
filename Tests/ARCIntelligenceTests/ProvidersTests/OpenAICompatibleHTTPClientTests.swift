//
//  OpenAICompatibleHTTPClientTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/03/2026.
//

import ARCNetworking
import Foundation
import Testing
@testable import ARCIntelligence

@Suite("OpenAI Compatible HTTP Client Tests", .tags(.unit)) struct OpenAICompatibleHTTPClientTests {
    // MARK: - Helpers

    private static let baseURL = URL(literal: "https://api.openai.com")
    private static let validHeaders = ["Authorization": "Bearer sk-test"]

    private func makeSUT(authHeaders: [String: String] = OpenAICompatibleHTTPClientTests.validHeaders,
                         httpClient: MockHTTPClient = MockHTTPClient()) -> (sut: OpenAICompatibleHTTPClient,
                                                                            mock: MockHTTPClient) {
        let sut = OpenAICompatibleHTTPClient(baseURL: OpenAICompatibleHTTPClientTests.baseURL,
                                             authHeaders: authHeaders,
                                             httpClient: httpClient)
        return (sut, httpClient)
    }

    private func makeRequest() -> OpenAIChatRequest {
        OpenAIChatRequest(model: "gpt-4o",
                          messages: [OpenAIChatMessage(role: "user", content: "Hello", toolCalls: nil,
                                                       toolCallId: nil)],
                          temperature: nil,
                          topP: nil,
                          maxTokens: nil,
                          stop: nil,
                          stream: false,
                          tools: nil,
                          toolChoice: nil,
                          responseFormat: nil)
    }

    private func makeStreamingRequest() -> OpenAIChatRequest {
        OpenAIChatRequest(model: "gpt-4o",
                          messages: [OpenAIChatMessage(role: "user", content: "Hello", toolCalls: nil,
                                                       toolCallId: nil)],
                          temperature: nil,
                          topP: nil,
                          maxTokens: nil,
                          stop: nil,
                          stream: true,
                          tools: nil,
                          toolChoice: nil,
                          responseFormat: nil)
    }

    private func makeResponse() -> OpenAIChatResponse {
        OpenAIChatResponse(id: "chatcmpl-test",
                           object: "chat.completion",
                           model: "gpt-4o",
                           choices: [OpenAIChatChoice(index: 0,
                                                      message: OpenAIChatChoiceMessage(role: "assistant",
                                                                                       content: "Hello!",
                                                                                       toolCalls: nil),
                                                      finishReason: "stop")],
                           usage: OpenAIUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30))
    }

    // MARK: - Authentication Validation

    @Test("Should throw providerNotConfigured when auth headers are empty") func throwsWhenAuthHeadersAreEmpty() async {
        // Given
        let (sut, _) = makeSUT(authHeaders: [:])

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendChatCompletion(makeRequest())
        }
    }

    @Test("Should throw providerNotConfigured when Authorization header is missing")
    func throwsWhenAuthorizationHeaderIsMissing() async {
        // Given
        let (sut, _) = makeSUT(authHeaders: ["X-Custom-Header": "value"])

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendChatCompletion(makeRequest())
        }
    }

    @Test("Should accept Authorization header in any casing")
    func acceptsAuthorizationHeaderInAnyCasing() async throws {
        // Given
        let (sut, mock) = makeSUT(authHeaders: ["AUTHORIZATION": "Bearer sk-test"])
        mock.responseToReturn = makeResponse()

        // When / Then — should not throw
        _ = try await sut.sendChatCompletion(makeRequest())
    }

    // MARK: - Send Chat Completion — Happy Path

    @Test("Should return response when request succeeds") func returnsResponseOnSuccess() async throws {
        // Given
        let (sut, mock) = makeSUT()
        mock.responseToReturn = makeResponse()

        // When
        let response = try await sut.sendChatCompletion(makeRequest())

        // Then
        #expect(response.choices.first?.message.content == "Hello!")
    }

    // MARK: - Send Chat Completion — Error Mapping

    @Test("Should map HTTPError.invalidURL to IntelligenceError.invalidRequest") func mapsInvalidURLError() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.invalidURL

        // When / Then
        await #expect(throws: IntelligenceError.self) {
            _ = try await sut.sendChatCompletion(makeRequest())
        }
    }

    @Test("Should map 401 status to IntelligenceError.authenticationFailed")
    func maps401ToAuthenticationFailed() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(statusCode: 401, data: Data())

        // When / Then
        await #expect(throws: IntelligenceError.authenticationFailed) {
            _ = try await sut.sendChatCompletion(makeRequest())
        }
    }

    @Test("Should map 429 status to IntelligenceError.rateLimitExceeded") func maps429ToRateLimitExceeded() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.errorToThrow = HTTPError.requestFailed(statusCode: 429, data: Data())

        // When / Then
        await #expect(throws: IntelligenceError.rateLimitExceeded) {
            _ = try await sut.sendChatCompletion(makeRequest())
        }
    }

    @Test("Should map 400 status to IntelligenceError.invalidRequest") func maps400ToInvalidRequest() {
        // Given
        let (sut, _) = makeSUT()

        // When
        let result = sut.mapHTTPStatusCode(400, data: nil)

        // Then
        guard case .invalidRequest = result else {
            Issue.record("Expected invalidRequest, got \(result)")
            return
        }
    }

    @Test("Should map 500 status to IntelligenceError.requestFailed with server error message")
    func maps500ToRequestFailed() {
        // Given
        let (sut, _) = makeSUT()

        // When
        let result = sut.mapHTTPStatusCode(500, data: nil)

        // Then
        guard case let .requestFailed(message) = result else {
            Issue.record("Expected requestFailed")
            return
        }
        #expect(message.contains("500"))
    }

    @Test("Should map 503 status to IntelligenceError.requestFailed within 5xx range") func maps503ToRequestFailed() {
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

    @Test("Should map HTTPError.decodingFailed to IntelligenceError.responseParseFailed")
    func mapsDecodingFailedToResponseParseFailed() async throws {
        // Given
        let (sut, mock) = makeSUT()
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad JSON"])
        mock.errorToThrow = HTTPError.decodingFailed(underlyingError)

        // When
        var thrownError: IntelligenceError?
        do {
            _ = try await sut.sendChatCompletion(makeRequest())
        } catch let error as IntelligenceError {
            thrownError = error
        }

        // Then
        guard case .responseParseFailed = thrownError else {
            Issue.record("Expected responseParseFailed, got \(String(describing: thrownError))")
            return
        }
    }

    // MARK: - Status Code Mapping with Error Body

    @Test("Should extract error message from response data") func extractsErrorMessageFromResponseData() {
        // Given
        let (sut, _) = makeSUT()
        let errorJSON = #"{"error":{"message":"Model not found"}}"#

        // When
        let result = sut.mapHTTPStatusCode(400, data: errorJSON.data(using: .utf8))

        // Then
        guard case let .invalidRequest(message) = result else {
            Issue.record("Expected invalidRequest")
            return
        }
        #expect(message == "Model not found")
    }

    @Test("Should include status code in default error message for unknown codes")
    func includesStatusCodeInDefaultMessage() {
        // Given
        let (sut, _) = makeSUT()

        // When
        let result = sut.mapHTTPStatusCode(418, data: nil)

        // Then
        guard case let .requestFailed(message) = result else {
            Issue.record("Expected requestFailed")
            return
        }
        #expect(message.contains("418"))
    }

    // MARK: - Stream Chat Completion — Happy Path

    @Test("Should yield chunk with finishReason when mock yields valid SSE lines")
    func streamChatCompletion_yieldsChunkWithFinishReason() async throws {
        // Given
        let (sut, mock) = makeSUT()
        // swiftlint:disable:next line_length
        let contentChunkLine = #"data: {"id":"chatcmpl-test","choices":[{"index":0,"delta":{"role":"assistant","content":"Hi"},"finish_reason":null}]}"#
        let finalChunkLine = #"data: {"id":"chatcmpl-test","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}"#
        mock.streamLinesToReturn = try [#require(contentChunkLine.data(using: .utf8)),
                                        #require(finalChunkLine.data(using: .utf8))]

        // When
        var chunks: [OpenAIStreamChunk] = []
        for try await chunk in sut.streamChatCompletion(makeStreamingRequest()) {
            chunks.append(chunk)
        }

        // Then
        let finishedChunk = chunks.first(where: { $0.choices?.first?.finishReason != nil })
        #expect(finishedChunk != nil)
        #expect(finishedChunk?.choices?.first?.finishReason == "stop")
    }

    // MARK: - Stream Chat Completion — Error Mapping

    @Test("Should map 401 HTTP error to authenticationFailed on streaming path")
    func streamChatCompletion_maps401ToAuthenticationFailed() async {
        // Given
        let (sut, mock) = makeSUT()
        mock.streamErrorToThrow = HTTPError.requestFailed(statusCode: 401, data: Data())

        // When
        var thrownError: IntelligenceError?
        do {
            for try await _ in sut.streamChatCompletion(makeStreamingRequest()) {}
        } catch let error as IntelligenceError {
            thrownError = error
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        // Then
        #expect(thrownError == .authenticationFailed)
    }
}
