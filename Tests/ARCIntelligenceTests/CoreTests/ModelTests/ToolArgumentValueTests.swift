//
//  ToolArgumentValueTests.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation
import Testing
@testable import ARCIntelligence

// MARK: - ToolArgumentValue Tests

@Suite("ToolArgumentValue Tests", .tags(.unit))
struct ToolArgumentValueTests {
    // MARK: - Helpers

    private func makeSUT() -> [String: ToolArgumentValue] {
        [
            "name": .string("Paris"),
            "count": .int(5),
            "ratio": .double(0.75),
            "active": .bool(true),
            "nothing": .null
        ]
    }

    private func encode(_ value: ToolArgumentValue) throws -> Data {
        try JSONEncoder().encode(value)
    }

    private func decode(_ data: Data) throws -> ToolArgumentValue {
        try JSONDecoder().decode(ToolArgumentValue.self, from: data)
    }

    // MARK: - Accessors

    @Test("stringValue returns value for .string case", .tags(.unit))
    func stringValue_returnsValueForStringCase() {
        // Given
        let sut = ToolArgumentValue.string("hello")

        // When / Then
        #expect(sut.stringValue == "hello")
        #expect(sut.intValue == nil)
        #expect(sut.doubleValue == nil)
        #expect(sut.boolValue == nil)
    }

    @Test("intValue returns value for .int case", .tags(.unit))
    func intValue_returnsValueForIntCase() {
        // Given
        let sut = ToolArgumentValue.int(42)

        // When / Then
        #expect(sut.intValue == 42)
        #expect(sut.stringValue == nil)
        #expect(sut.doubleValue == nil)
        #expect(sut.boolValue == nil)
    }

    @Test("doubleValue returns value for .double case", .tags(.unit))
    func doubleValue_returnsValueForDoubleCase() {
        // Given
        let sut = ToolArgumentValue.double(3.14)

        // When / Then
        #expect(sut.doubleValue == 3.14)
        #expect(sut.stringValue == nil)
        #expect(sut.intValue == nil)
        #expect(sut.boolValue == nil)
    }

    @Test("boolValue returns value for .bool case", .tags(.unit))
    func boolValue_returnsValueForBoolCase() {
        // Given
        let sut = ToolArgumentValue.bool(false)

        // When / Then
        #expect(sut.boolValue == false)
        #expect(sut.stringValue == nil)
        #expect(sut.intValue == nil)
        #expect(sut.doubleValue == nil)
    }

    // MARK: - asString / description

    @Test("asString converts all cases to string representation", .tags(.unit))
    func asString_convertsAllCases() {
        // Given / When / Then
        #expect(ToolArgumentValue.string("hi").asString == "hi")
        #expect(ToolArgumentValue.int(7).asString == "7")
        #expect(ToolArgumentValue.double(1.5).asString == "1.5")
        #expect(ToolArgumentValue.bool(true).asString == "true")
        #expect(ToolArgumentValue.null.asString == "null")
    }

    @Test("description matches asString", .tags(.unit))
    func description_matchesAsString() {
        // Given
        let values: [ToolArgumentValue] = [
            .string("test"), .int(1), .double(2.0), .bool(false), .null
        ]

        // When / Then
        for value in values {
            #expect(value.description == value.asString)
        }
    }

    // MARK: - Equatable

    @Test("equal values are equal", .tags(.unit))
    func equatable_equalValuesAreEqual() {
        #expect(ToolArgumentValue.string("a") == .string("a"))
        #expect(ToolArgumentValue.int(1) == .int(1))
        #expect(ToolArgumentValue.double(0.5) == .double(0.5))
        #expect(ToolArgumentValue.bool(true) == .bool(true))
        #expect(ToolArgumentValue.null == .null)
        #expect(ToolArgumentValue.array([.int(1)]) == .array([.int(1)]))
        #expect(ToolArgumentValue.object(["k": .string("v")]) == .object(["k": .string("v")]))
    }

    @Test("different cases are not equal", .tags(.unit))
    func equatable_differentCasesAreNotEqual() {
        #expect(ToolArgumentValue.string("a") != .int(1))
        #expect(ToolArgumentValue.int(1) != .int(2))
        #expect(ToolArgumentValue.null != .bool(false))
    }

    // MARK: - Codable: Encode

    @Test("encode string produces JSON string", .tags(.unit))
    func encode_stringProducesJSONString() throws {
        // Given
        let sut = ToolArgumentValue.string("Paris")

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        // Then
        #expect(json as? String == "Paris")
    }

    @Test("encode int produces JSON number", .tags(.unit))
    func encode_intProducesJSONNumber() throws {
        // Given
        let sut = ToolArgumentValue.int(42)

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        // Then
        #expect(json as? Int == 42)
    }

    @Test("encode double produces JSON number", .tags(.unit))
    func encode_doubleProducesJSONNumber() throws {
        // Given
        let sut = ToolArgumentValue.double(1.5)

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        // Then
        #expect(json as? Double == 1.5)
    }

    @Test("encode bool produces JSON bool", .tags(.unit))
    func encode_boolProducesJSONBool() throws {
        // Given
        let sut = ToolArgumentValue.bool(true)

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        // Then
        #expect(json as? Bool == true)
    }

    @Test("encode null produces JSON null", .tags(.unit))
    func encode_nullProducesJSONNull() throws {
        // Given
        let sut = ToolArgumentValue.null

        // When
        let data = try encode(sut)

        // Then — JSON null serialises as "null" literal
        #expect(String(data: data, encoding: .utf8) == "null")
    }

    @Test("encode array produces JSON array", .tags(.unit))
    func encode_arrayProducesJSONArray() throws {
        // Given
        let sut = ToolArgumentValue.array([.string("a"), .int(1)])

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Any]

        // Then
        #expect(json?.count == 2)
        #expect(json?.first as? String == "a")
        #expect(json?.last as? Int == 1)
    }

    @Test("encode object produces JSON object", .tags(.unit))
    func encode_objectProducesJSONObject() throws {
        // Given
        let sut = ToolArgumentValue.object(["city": .string("Rome"), "pop": .int(3_000_000)])

        // When
        let data = try encode(sut)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]

        // Then
        #expect(json?["city"] as? String == "Rome")
        #expect(json?["pop"] as? Int == 3_000_000)
    }

    // MARK: - Codable: Decode

    @Test("decode string JSON produces .string", .tags(.unit))
    func decode_stringJSONProducesString() throws {
        // Given
        let json = Data("\"hello\"".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .string("hello"))
    }

    @Test("decode integer JSON produces .int", .tags(.unit))
    func decode_integerJSONProducesInt() throws {
        // Given
        let json = Data("99".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .int(99))
    }

    @Test("decode float JSON produces .double", .tags(.unit))
    func decode_floatJSONProducesDouble() throws {
        // Given
        let json = Data("3.14".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .double(3.14))
    }

    @Test("decode boolean JSON produces .bool", .tags(.unit))
    func decode_booleanJSONProducesBool() throws {
        // Given
        let trueJSON = Data("true".utf8)
        let falseJSON = Data("false".utf8)

        // When
        let trueResult = try decode(trueJSON)
        let falseResult = try decode(falseJSON)

        // Then
        #expect(trueResult == .bool(true))
        #expect(falseResult == .bool(false))
    }

    @Test("decode null JSON produces .null", .tags(.unit))
    func decode_nullJSONProducesNull() throws {
        // Given
        let json = Data("null".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .null)
    }

    @Test("decode array JSON produces .array", .tags(.unit))
    func decode_arrayJSONProducesArray() throws {
        // Given
        let json = Data("[\"x\", 2]".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .array([.string("x"), .int(2)]))
    }

    @Test("decode object JSON produces .object", .tags(.unit))
    func decode_objectJSONProducesObject() throws {
        // Given
        let json = Data("{\"k\":\"v\"}".utf8)

        // When
        let result = try decode(json)

        // Then
        #expect(result == .object(["k": .string("v")]))
    }

    // MARK: - Codable: Round-trip

    @Test("encode then decode produces equal value for all cases", .tags(.unit))
    func codable_roundTripProducesEqualValue() throws {
        // Given
        let values: [ToolArgumentValue] = [
            .string("test"),
            .int(123),
            .double(4.56),
            .bool(true),
            .bool(false),
            .null,
            .array([.string("a"), .int(1), .bool(false)]),
            .object(["key": .string("value"), "count": .int(3)])
        ]

        for original in values {
            // When
            let data = try encode(original)
            let decoded = try decode(data)

            // Then
            #expect(decoded == original)
        }
    }

    // MARK: - toStringDictionary

    @Test("toStringDictionary converts all value types to strings", .tags(.unit))
    func toStringDictionary_convertsAllTypes() {
        // Given
        let dict = makeSUT()

        // When
        let result = ToolArgumentValue.toStringDictionary(dict)

        // Then
        #expect(result["name"] == "Paris")
        #expect(result["count"] == "5")
        #expect(result["active"] == "true")
        #expect(result["nothing"] == "null")
        #expect(result.count == dict.count)
    }

    @Test("toStringDictionary preserves all keys", .tags(.unit))
    func toStringDictionary_preservesAllKeys() {
        // Given
        let dict: [String: ToolArgumentValue] = ["a": .string("x"), "b": .int(1), "c": .null]

        // When
        let result = ToolArgumentValue.toStringDictionary(dict)

        // Then
        #expect(result.keys.sorted() == ["a", "b", "c"])
    }
}
