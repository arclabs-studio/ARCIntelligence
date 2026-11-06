//
//  ResponseFormatTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 06/11/2026.
//

import Testing
@testable import ARCIntelligence

@Suite("ResponseFormat Tests", .tags(.unit)) struct ResponseFormatTests {
    @Test("JSON formats with different schemas are not equal") func differentSchemasAreNotEqual() {
        // Given
        let arrayOfStrings = ResponseFormat.json(schema: .object(["type": .string("ARRAY")]))
        let object = ResponseFormat.json(schema: .object(["type": .string("OBJECT")]))

        // Then
        #expect(arrayOfStrings != object)
    }

    @Test("JSON formats with the same schema are equal") func sameSchemaIsEqual() {
        // Given
        let schema: JSONValue = .object(["type": .string("ARRAY"), "items": .object(["type": .string("STRING")])])

        // Then
        #expect(ResponseFormat.json(schema: schema) == ResponseFormat.json(schema: schema))
    }

    @Test("A schema-less JSON format differs from a constrained one") func schemaLessDiffersFromConstrained() {
        // Then
        #expect(ResponseFormat.json() != ResponseFormat.json(schema: .object([:])))
        #expect(ResponseFormat.json() == ResponseFormat.json(schema: nil))
    }

    @Test("Text differs from JSON") func textDiffersFromJSON() {
        // Then
        #expect(ResponseFormat.text != ResponseFormat.json())
    }
}
