# Tool Calling

Extend model capabilities with custom tools using the `ToolProvider` protocol.

## Overview

Tool calling allows the model to interact with external code to fetch information, perform actions, or integrate with other frameworks. The model decides when to call tools based on the user's prompt and the tools' descriptions.

On Apple platforms (iOS 26+), this maps to the `Tool` protocol and `LanguageModelSession(tools:)` API from Foundation Models.

## Defining a Tool

Create a tool by conforming to the `IntelligenceTool` protocol:

```swift
import ARCIntelligence

struct WeatherTool: IntelligenceTool {
    let name = "getWeather"
    let description = "Get the current weather for a city"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(
            parameters: [
                ToolParameter(
                    name: "city",
                    type: .string,
                    description: "The city name to get weather for"
                )
            ],
            required: ["city"]
        )
    }

    func execute(arguments: [String: Any]) async throws -> String {
        guard let city = arguments["city"] as? String else {
            throw IntelligenceError.invalidRequest("Missing city parameter")
        }

        // Call your weather API here
        let weather = await fetchWeather(for: city)
        return "Weather in \(city): \(weather.temperature)F, \(weather.condition)"
    }
}
```

## Using Tools with a Provider

Pass your tools to the provider when generating responses:

```swift
let provider = ARCIntelligence.toolProvider()

let response = try await provider.respond(
    to: "What's the weather like in San Francisco?",
    tools: [WeatherTool()],
    configuration: .default
)

print(response.content)
// Output: "The current weather in San Francisco is 68F and sunny."
```

## Getting Tool Call Information

Use `respondWithToolCalls` to see which tools were called:

```swift
let (response, toolCalls) = try await provider.respondWithToolCalls(
    to: "What's the weather in Boston and New York?",
    tools: [WeatherTool()],
    configuration: .default
)

print("Response: \(response.content)")
print("Tool calls made: \(toolCalls.count)")

for call in toolCalls {
    print("- \(call.toolName): \(call.arguments)")
    print("  Output: \(call.output)")
    print("  Duration: \(call.duration)s")
}
```

## Parameter Types

Tools can accept various parameter types:

```swift
struct CalculatorTool: IntelligenceTool {
    let name = "calculate"
    let description = "Perform mathematical calculations"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(
            parameters: [
                ToolParameter(
                    name: "operation",
                    type: .string,
                    description: "The operation to perform",
                    enumValues: ["add", "subtract", "multiply", "divide"]
                ),
                ToolParameter(
                    name: "a",
                    type: .number,
                    description: "First operand"
                ),
                ToolParameter(
                    name: "b",
                    type: .number,
                    description: "Second operand"
                )
            ],
            required: ["operation", "a", "b"]
        )
    }

    func execute(arguments: [String: Any]) async throws -> String {
        guard let operation = arguments["operation"] as? String,
              let a = arguments["a"] as? Double,
              let b = arguments["b"] as? Double else {
            throw IntelligenceError.invalidRequest("Invalid parameters")
        }

        let result: Double
        switch operation {
        case "add": result = a + b
        case "subtract": result = a - b
        case "multiply": result = a * b
        case "divide":
            guard b != 0 else {
                return "Error: Division by zero"
            }
            result = a / b
        default:
            return "Error: Unknown operation"
        }

        return String(format: "%.2f", result)
    }
}
```

## Multiple Tools

You can provide multiple tools and the model will choose which to use:

```swift
struct SearchTool: IntelligenceTool {
    let name = "search"
    let description = "Search the web for information"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(
            parameters: [
                ToolParameter(
                    name: "query",
                    type: .string,
                    description: "The search query"
                )
            ],
            required: ["query"]
        )
    }

    func execute(arguments: [String: Any]) async throws -> String {
        let query = arguments["query"] as? String ?? ""
        // Perform search
        return "Search results for: \(query)"
    }
}

// Use multiple tools
let response = try await provider.respond(
    to: "What's 25 * 4, and what's the weather in Miami?",
    tools: [CalculatorTool(), WeatherTool(), SearchTool()],
    configuration: .default
)
```

## Tools Without Parameters

Some tools don't need parameters:

```swift
struct CurrentTimeTool: IntelligenceTool {
    let name = "getCurrentTime"
    let description = "Get the current date and time"

    // parametersSchema defaults to nil

    func execute(arguments: [String: Any]) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
}
```

## Error Handling in Tools

Handle errors gracefully within your tools:

```swift
struct DatabaseTool: IntelligenceTool {
    let name = "queryDatabase"
    let description = "Query the user database"

    var parametersSchema: ToolParametersSchema? {
        ToolParametersSchema(
            parameters: [
                ToolParameter(
                    name: "userId",
                    type: .string,
                    description: "The user ID to look up"
                )
            ],
            required: ["userId"]
        )
    }

    func execute(arguments: [String: Any]) async throws -> String {
        guard let userId = arguments["userId"] as? String else {
            return "Error: Missing user ID"
        }

        do {
            let user = try await database.findUser(id: userId)
            return "User: \(user.name), Email: \(user.email)"
        } catch {
            return "Error: User not found"
        }
    }
}
```

## Testing Tool Providers

Use `MockToolProvider` for testing:

```swift
import ARCIntelligenceMocks

@Test("Tool provider handles weather request")
func toolProviderHandlesWeatherRequest() async throws {
    let mock = MockToolProvider(
        response: "It's sunny in Boston",
        toolCallsToSimulate: [
            ToolCallRecord(
                toolName: "getWeather",
                arguments: ["city": "Boston"],
                output: "72F, Sunny",
                duration: 0.1
            )
        ]
    )

    let (response, toolCalls) = try await mock.respondWithToolCalls(
        to: "What's the weather in Boston?",
        tools: [],
        configuration: .default
    )

    #expect(response.content == "It's sunny in Boston")
    #expect(toolCalls.count == 1)
    #expect(toolCalls[0].toolName == "getWeather")
}
```

Test individual tools with `MockTool`:

```swift
@Test("Mock tool returns expected output")
func mockToolReturnsExpectedOutput() async throws {
    let tool = MockTool(
        name: "testTool",
        description: "A test tool",
        responseToReturn: "Test output"
    )

    let result = try await tool.execute(arguments: [:])
    #expect(result == "Test output")
}
```

## Best Practices

1. **Write clear descriptions**: The model uses the description to decide when to call the tool
2. **Validate parameters**: Always validate and handle missing or invalid parameters
3. **Return structured output**: Return clear, parseable results from your tools
4. **Handle errors gracefully**: Return error messages rather than throwing when possible
5. **Keep tools focused**: Each tool should do one thing well
6. **Document parameter constraints**: Use `enumValues` and `range` to constrain inputs

## See Also

- ``ToolProvider``
- ``IntelligenceTool``
- ``ToolParametersSchema``
- ``ToolParameter``
- ``ToolCallRecord``
- <doc:Testing>
