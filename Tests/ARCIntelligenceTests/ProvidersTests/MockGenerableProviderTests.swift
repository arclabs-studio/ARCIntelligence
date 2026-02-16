//
//  MockGenerableProviderTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Testing
@testable import ARCIntelligence
@testable import ARCIntelligenceMocks

@Suite("Mock Generable Provider Tests")
struct MockGenerableProviderTests {
    // MARK: - Test Types

    struct TestPerson: Codable, Sendable, Equatable {
        let name: String
        let age: Int
    }

    struct TestProduct: Codable, Sendable, Equatable {
        let title: String
        let price: Double
        let inStock: Bool
    }

    // MARK: - Availability Tests

    @Test("Mock generable provider is always available")
    func isAvailable() async {
        let provider = MockGenerableProvider()
        let available = await provider.isAvailable()
        #expect(available)
    }

    // MARK: - Generate Tests

    @Test("Generate returns decoded type from JSON response")
    func generateReturnsDecodedType() async throws {
        let json = #"{"name": "Alice", "age": 30}"#
        let provider = MockGenerableProvider(jsonResponse: json)

        let result: TestPerson = try await provider.generate(TestPerson.self,
                                                             prompt: "Generate a person",
                                                             configuration: .default)

        #expect(result.name == "Alice")
        #expect(result.age == 30)
    }

    @Test("Generate handles complex types")
    func generateHandlesComplexTypes() async throws {
        let json = #"{"title": "Widget", "price": 19.99, "inStock": true}"#
        let provider = MockGenerableProvider(jsonResponse: json)

        let result: TestProduct = try await provider.generate(TestProduct.self,
                                                              prompt: "Generate a product",
                                                              configuration: .default)

        #expect(result.title == "Widget")
        #expect(result.price == 19.99)
        #expect(result.inStock == true)
    }

    @Test("Generate throws error when no JSON configured")
    func generateThrowsErrorWhenNoJSON() async {
        let provider = MockGenerableProvider()

        await #expect(throws: IntelligenceError.self) {
            let _: TestPerson = try await provider.generate(TestPerson.self,
                                                            prompt: "Generate a person",
                                                            configuration: .default)
        }
    }

    @Test("Generate throws error when JSON is invalid for type")
    func generateThrowsErrorForInvalidJSON() async {
        let json = #"{"invalid": "data"}"#
        let provider = MockGenerableProvider(jsonResponse: json)

        await #expect(throws: IntelligenceError.self) {
            let _: TestPerson = try await provider.generate(TestPerson.self,
                                                            prompt: "Generate a person",
                                                            configuration: .default)
        }
    }

    @Test("Generate throws configured error when shouldFail is true")
    func generateThrowsConfiguredError() async {
        let expectedError = IntelligenceError.modelNotReady
        let provider = MockGenerableProvider(shouldFail: true,
                                             errorToThrow: expectedError)

        await #expect(throws: IntelligenceError.self) {
            let _: TestPerson = try await provider.generate(TestPerson.self,
                                                            prompt: "Generate",
                                                            configuration: CompletionConfiguration.default)
        }
    }

    // MARK: - Schema Description Tests

    @Test("Generate with schema description works")
    func generateWithSchemaDescription() async throws {
        let json = #"{"name": "Bob", "age": 25}"#
        let provider = MockGenerableProvider(jsonResponse: json)

        let result: TestPerson = try await provider.generate(TestPerson.self,
                                                             prompt: "Generate a person",
                                                             schemaDescription: "A person with name and age",
                                                             configuration: .default)

        #expect(result.name == "Bob")
        #expect(result.age == 25)
    }

    // MARK: - Complete Tests

    @Test("Complete returns JSON as content")
    func completeReturnsJSONAsContent() async throws {
        let json = #"{"key": "value"}"#
        let provider = MockGenerableProvider(jsonResponse: json)

        let response = try await provider.complete(prompt: "Test",
                                                   configuration: .default)

        #expect(response.content == json)
    }

    @Test("Complete returns empty object when no JSON configured")
    func completeReturnsEmptyObjectWhenNoJSON() async throws {
        let provider = MockGenerableProvider()

        let response = try await provider.complete(prompt: "Test",
                                                   configuration: .default)

        #expect(response.content == "{}")
    }
}
