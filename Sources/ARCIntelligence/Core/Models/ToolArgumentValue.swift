//
//  ToolArgumentValue.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

/// A type-safe, `Sendable` value type for tool arguments.
///
/// Replaces untyped `[String: Any]` dictionaries with a fully typed,
/// `Codable` and `Sendable` alternative for passing arguments to tools.
///
/// ## Usage
/// ```swift
/// let args: [String: ToolArgumentValue] = [
///     "city": .string("San Francisco"),
///     "units": .string("fahrenheit"),
///     "detailed": .bool(true)
/// ]
/// let output = try await tool.execute(arguments: args)
/// ```
public enum ToolArgumentValue: Sendable, Codable, Equatable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([ToolArgumentValue])
    case object([String: ToolArgumentValue])

    // MARK: - Convenience Accessors

    /// Returns the string value if this is a `.string` case, nil otherwise.
    public var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    /// Returns the integer value if this is an `.int` case, nil otherwise.
    public var intValue: Int? {
        if case let .int(value) = self { return value }
        return nil
    }

    /// Returns the double value if this is a `.double` case, nil otherwise.
    public var doubleValue: Double? {
        if case let .double(value) = self { return value }
        return nil
    }

    /// Returns the boolean value if this is a `.bool` case, nil otherwise.
    public var boolValue: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }

    /// Returns a string representation of the value, regardless of type.
    public var asString: String {
        switch self {
        case let .string(value): value
        case let .int(value): "\(value)"
        case let .double(value): "\(value)"
        case let .bool(value): "\(value)"
        case .null: "null"
        case let .array(value): "\(value)"
        case let .object(value): "\(value)"
        }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        asString
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([ToolArgumentValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: ToolArgumentValue].self) {
            self = .object(value)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Unable to decode ToolArgumentValue")
            throw DecodingError.typeMismatch(ToolArgumentValue.self, context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

// MARK: - String Dictionary Conversion

extension ToolArgumentValue {
    /// Convert a `[String: ToolArgumentValue]` to `[String: String]` for logging/metadata.
    public static func toStringDictionary(_ arguments: [String: ToolArgumentValue]) -> [String: String] {
        arguments.compactMapValues { value -> String? in
            value.asString
        }
    }
}
