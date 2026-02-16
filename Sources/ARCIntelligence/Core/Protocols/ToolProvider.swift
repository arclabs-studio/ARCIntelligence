//
//  ToolProvider.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 14/01/2026.
//

import Foundation

/// Protocol for providers that support tool calling.
///
/// Tool calling allows the model to interact with external code to fetch
/// information, perform actions, or integrate with other frameworks.
///
/// On Apple platforms (iOS 26+), this maps to the `Tool` protocol and
/// `LanguageModelSession(tools:)` API.
///
/// ## Usage
/// ```swift
/// // Define a tool
/// struct WeatherTool: IntelligenceTool {
///     let name = "getWeather"
///     let description = "Get current weather for a city"
///
///     func execute(arguments: [String: Any]) async throws -> String {
///         let city = arguments["city"] as? String ?? "Unknown"
///         return "Weather in \(city): 72°F, Sunny"
///     }
/// }
///
/// // Use the provider with tools
/// let response = try await provider.respond(
///     to: "What's the weather in San Francisco?",
///     tools: [WeatherTool()],
///     configuration: .default
/// )
/// ```
public protocol ToolProvider: IntelligenceProvider {
    /// Generate a response that may use the provided tools.
    ///
    /// The model will decide whether to call tools based on the prompt.
    /// Tools are called automatically and their output is incorporated
    /// into the final response.
    ///
    /// - Parameters:
    ///   - prompt: The input prompt.
    ///   - tools: Available tools the model can call.
    ///   - configuration: Configuration for the generation.
    /// - Returns: The generated response, potentially informed by tool calls.
    /// - Throws: `IntelligenceError` if generation or tool execution fails.
    func respond(to prompt: String,
                 tools: [any IntelligenceTool],
                 configuration: CompletionConfiguration) async throws -> IntelligenceResponse

    /// Generate a response with tools, returning tool call information.
    ///
    /// - Parameters:
    ///   - prompt: The input prompt.
    ///   - tools: Available tools the model can call.
    ///   - configuration: Configuration for the generation.
    /// - Returns: A tuple containing the response and any tool calls made.
    /// - Throws: `IntelligenceError` if generation or tool execution fails.
    func respondWithToolCalls(to prompt: String,
                              tools: [any IntelligenceTool],
                              configuration: CompletionConfiguration) async throws -> (response: IntelligenceResponse,
                                                                                       toolCalls: [ToolCallRecord])
}

// MARK: - Tool Protocol

/// A tool that can be called by the model during generation.
///
/// Tools extend the model's capabilities by allowing it to:
/// - Query databases or APIs
/// - Perform calculations
/// - Access device features
/// - Integrate with other frameworks
public protocol IntelligenceTool: Sendable {
    /// Unique name identifying this tool.
    var name: String { get }

    /// Human-readable description of what the tool does.
    /// The model uses this to decide when to call the tool.
    var description: String { get }

    /// JSON schema describing the tool's parameters.
    /// If nil, the tool accepts no parameters.
    var parametersSchema: ToolParametersSchema? { get }

    /// Execute the tool with the given arguments.
    ///
    /// - Parameter arguments: Arguments provided by the model.
    /// - Returns: The tool's output as a string.
    /// - Throws: Any error that occurs during execution.
    func execute(arguments: [String: Any]) async throws -> String
}

// MARK: - Tool Parameters Schema

/// Schema describing a tool's parameters.
public struct ToolParametersSchema: Sendable, Equatable {
    /// Parameter definitions.
    public let parameters: [ToolParameter]

    /// Required parameter names.
    public let required: [String]

    public init(parameters: [ToolParameter], required: [String] = []) {
        self.parameters = parameters
        self.required = required
    }
}

/// A single tool parameter definition.
public struct ToolParameter: Sendable, Equatable {
    /// Parameter name.
    public let name: String

    /// Parameter type.
    public let type: ParameterType

    /// Human-readable description.
    public let description: String

    /// Valid values for enum types.
    public let enumValues: [String]?

    /// Range constraints for numeric types.
    public let range: ClosedRange<Double>?

    public init(name: String,
                type: ParameterType,
                description: String,
                enumValues: [String]? = nil,
                range: ClosedRange<Double>? = nil) {
        self.name = name
        self.type = type
        self.description = description
        self.enumValues = enumValues
        self.range = range
    }

    /// Supported parameter types.
    public enum ParameterType: String, Sendable, Equatable {
        case string
        case integer
        case number
        case boolean
        case array
        case object
    }
}

// MARK: - Tool Call Record

/// Record of a tool call made during generation.
public struct ToolCallRecord: Sendable, Equatable {
    /// Name of the tool that was called.
    public let toolName: String

    /// Arguments passed to the tool.
    public let arguments: [String: String]

    /// Output returned by the tool.
    public let output: String

    /// Duration of the tool call in seconds.
    public let duration: TimeInterval

    public init(toolName: String,
                arguments: [String: String],
                output: String,
                duration: TimeInterval) {
        self.toolName = toolName
        self.arguments = arguments
        self.output = output
        self.duration = duration
    }
}

// MARK: - Default Implementations

extension IntelligenceTool {
    /// Default: no parameters schema.
    public var parametersSchema: ToolParametersSchema? {
        nil
    }
}

extension ToolProvider {
    /// Default implementation that discards tool call information.
    public func respond(to prompt: String,
                        tools: [any IntelligenceTool],
                        configuration: CompletionConfiguration) async throws -> IntelligenceResponse {
        let (response, _) = try await respondWithToolCalls(to: prompt,
                                                           tools: tools,
                                                           configuration: configuration)
        return response
    }
}
