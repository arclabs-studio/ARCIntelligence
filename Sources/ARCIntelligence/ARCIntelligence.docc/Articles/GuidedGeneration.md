# Guided Generation

Generate structured Swift types directly from prompts using the `GenerableProvider` protocol.

## Overview

Guided generation allows the model to produce output that conforms to a specific Swift type, rather than raw strings. This provides strong guarantees about the response format and eliminates manual parsing.

On Apple platforms (iOS 26+), this maps to the `@Generable` macro and `LanguageModelSession.respond(to:generating:)` API from Foundation Models.

## Basic Usage

Define your output type as a `Codable` and `Sendable` struct:

```swift
import ARCIntelligence

struct MovieReview: Codable, Sendable {
    let title: String
    let rating: Int
    let summary: String
    let pros: [String]
    let cons: [String]
}
```

Then use the `GenerableProvider` to generate structured data:

```swift
let provider = ARCIntelligence.generableProvider()

let review: MovieReview = try await provider.generate(
    MovieReview.self,
    prompt: "Review the movie Inception",
    configuration: .factual
)

print("\(review.title): \(review.rating)/10")
print("Summary: \(review.summary)")
print("Pros: \(review.pros.joined(separator: ", "))")
print("Cons: \(review.cons.joined(separator: ", "))")
```

## Schema Descriptions

For better results, you can provide a schema description that helps the model understand how to populate your type:

```swift
let review: MovieReview = try await provider.generate(
    MovieReview.self,
    prompt: "Review the movie The Matrix",
    schemaDescription: """
        A structured movie review with:
        - title: The official movie title
        - rating: Score from 1-10
        - summary: 2-3 sentence overview
        - pros: List of positive aspects (max 5)
        - cons: List of negative aspects (max 3)
        """,
    configuration: .factual
)
```

## Supported Types

Guided generation works with any type that conforms to `Codable` and `Sendable`:

### Simple Types

```swift
struct Person: Codable, Sendable {
    let name: String
    let age: Int
    let email: String
}

let person: Person = try await provider.generate(
    Person.self,
    prompt: "Generate a fictional person profile",
    configuration: .creative
)
```

### Nested Types

```swift
struct Address: Codable, Sendable {
    let street: String
    let city: String
    let country: String
}

struct Company: Codable, Sendable {
    let name: String
    let industry: String
    let headquarters: Address
    let employees: Int
}

let company: Company = try await provider.generate(
    Company.self,
    prompt: "Generate a tech startup profile",
    configuration: .creative
)
```

### Arrays and Optionals

```swift
struct Recipe: Codable, Sendable {
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int?
    let cookTime: Int?
    let servings: Int
}

let recipe: Recipe = try await provider.generate(
    Recipe.self,
    prompt: "Create a simple pasta recipe",
    configuration: .creative
)
```

### Enums

```swift
enum Priority: String, Codable, Sendable {
    case low, medium, high, critical
}

struct Task: Codable, Sendable {
    let title: String
    let description: String
    let priority: Priority
    let dueDate: String?
}

let task: Task = try await provider.generate(
    Task.self,
    prompt: "Create a task for reviewing pull requests",
    configuration: .factual
)
```

## Configuration Options

Use different configurations based on your needs:

```swift
// For factual, deterministic output
let factualResult = try await provider.generate(
    MyType.self,
    prompt: "...",
    configuration: .factual
)

// For creative output
let creativeResult = try await provider.generate(
    MyType.self,
    prompt: "...",
    configuration: .creative
)

// Custom configuration
let customConfig = CompletionConfiguration(
    temperature: 0.5,
    maxTokens: 1000
)
let customResult = try await provider.generate(
    MyType.self,
    prompt: "...",
    configuration: customConfig
)
```

## Error Handling

Handle generation errors appropriately:

```swift
do {
    let result: MyType = try await provider.generate(
        MyType.self,
        prompt: "...",
        configuration: .default
    )
    // Use result
} catch IntelligenceError.providerUnavailable {
    print("Provider not available on this device")
} catch IntelligenceError.responseParseFailed(let reason) {
    print("Failed to parse response: \(reason)")
} catch IntelligenceError.requestFailed(let reason) {
    print("Request failed: \(reason)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Testing

Use `MockGenerableProvider` for testing:

```swift
import ARCIntelligenceMocks

@Test("Generate movie review")
func generateMovieReview() async throws {
    let mock = MockGenerableProvider(
        jsonResponse: #"{"title": "Test Movie", "rating": 8, "summary": "Great film", "pros": ["Acting"], "cons": ["Pacing"]}"#
    )

    let review: MovieReview = try await mock.generate(
        MovieReview.self,
        prompt: "Review a movie",
        configuration: .default
    )

    #expect(review.title == "Test Movie")
    #expect(review.rating == 8)
}
```

## Best Practices

1. **Keep types simple**: Complex nested structures may produce less reliable results
2. **Use clear property names**: Descriptive names help the model understand intent
3. **Provide schema descriptions**: For complex types, a description improves accuracy
4. **Validate output**: Even with structured generation, validate critical fields
5. **Handle optionals**: Use optionals for fields that may not always be populated

## See Also

- ``GenerableProvider``
- ``CompletionConfiguration``
- ``IntelligenceError``
- <doc:Testing>
