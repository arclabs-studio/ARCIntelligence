# Content Tagging

Extract topics, emotions, actions, and objects from text using the `ContentTaggingProvider` protocol.

## Overview

Content tagging uses a specialized model to identify semantic elements in text. Tags are consistent, lowercase, and typically one to three words. This is useful for categorization, search optimization, and content analysis.

On Apple platforms (iOS 26+), this maps to `SystemLanguageModel.UseCase.contentTagging` from Foundation Models.

## Basic Usage

Generate tags for any text content:

```swift
import ARCIntelligence

let provider = ARCIntelligence.contentTaggingProvider()

let tags = try await provider.generateTags(
    for: "I love hiking in the mountains on sunny days!",
    categories: [.topic, .emotion, .action],
    maxTags: 5
)

for tag in tags {
    print("\(tag.category.rawValue): \(tag.value) (\(tag.confidence))")
}
// Output:
// topic: hiking (0.95)
// topic: mountains (0.92)
// emotion: joy (0.88)
// action: outdoor activity (0.85)
```

## Tag Categories

ARCIntelligence supports four tag categories:

### Topic Tags

Topics discussed in the content:

```swift
let tags = try await provider.generateTags(
    for: "Swift is a powerful programming language for iOS development",
    categories: [.topic],
    maxTags: 5
)
// Tags: "swift", "programming", "ios", "development"
```

### Action Tags

Actions being performed or discussed:

```swift
let tags = try await provider.generateTags(
    for: "Running through the park while listening to music",
    categories: [.action],
    maxTags: 5
)
// Tags: "running", "listening", "exercising"
```

### Object Tags

Objects mentioned in the content:

```swift
let tags = try await provider.generateTags(
    for: "I bought a new laptop and wireless headphones",
    categories: [.object],
    maxTags: 5
)
// Tags: "laptop", "headphones", "electronics"
```

### Emotion Tags

Emotions expressed in the content:

```swift
let tags = try await provider.generateTags(
    for: "I'm so excited about the upcoming vacation!",
    categories: [.emotion],
    maxTags: 5
)
// Tags: "excited", "anticipation", "happy"
```

## Multiple Categories

Request tags from multiple categories at once:

```swift
let tags = try await provider.generateTags(
    for: "I'm frustrated because my computer crashed while I was coding",
    categories: [.topic, .emotion, .action, .object],
    maxTags: 3
)

// Group by category
let grouped = Dictionary(grouping: tags) { $0.category }

for (category, categoryTags) in grouped {
    print("\(category.rawValue):")
    for tag in categoryTags {
        print("  - \(tag.value)")
    }
}
```

## Batch Processing

Process multiple texts efficiently:

```swift
let texts = [
    "I love cooking Italian food",
    "Running a marathon is challenging but rewarding",
    "The new iPhone has amazing camera features"
]

let batchResults = try await provider.generateTagsBatch(
    for: texts,
    categories: [.topic, .emotion],
    maxTagsPerText: 3
)

for (index, tags) in batchResults.enumerated() {
    print("Text \(index + 1):")
    for tag in tags {
        print("  - \(tag.value) (\(tag.category.rawValue))")
    }
}
```

## Working with ContentTag

The `ContentTag` type provides structured tag information:

```swift
let tags = try await provider.generateTags(
    for: "Amazing performance at the concert!",
    categories: TagCategory.allCases,
    maxTags: 10
)

for tag in tags {
    print("ID: \(tag.id)")
    print("Value: \(tag.value)")
    print("Category: \(tag.category.rawValue)")
    print("Confidence: \(String(format: "%.2f", tag.confidence))")
    print("---")
}
```

### Filtering by Confidence

Filter tags by confidence threshold:

```swift
let highConfidenceTags = tags.filter { $0.confidence >= 0.8 }
```

### Sorting Tags

Sort by confidence or alphabetically:

```swift
// By confidence (highest first)
let sortedByConfidence = tags.sorted { $0.confidence > $1.confidence }

// Alphabetically
let sortedAlphabetically = tags.sorted { $0.value < $1.value }
```

## Use Cases

### Content Categorization

```swift
func categorizeArticle(_ content: String) async throws -> [String: [String]] {
    let provider = ARCIntelligence.contentTaggingProvider()

    let tags = try await provider.generateTags(
        for: content,
        categories: [.topic],
        maxTags: 5
    )

    let categories = tags.map { $0.value }
    return ["categories": categories]
}
```

### Sentiment Analysis

```swift
func analyzeSentiment(_ text: String) async throws -> String {
    let provider = ARCIntelligence.contentTaggingProvider()

    let tags = try await provider.generateTags(
        for: text,
        categories: [.emotion],
        maxTags: 3
    )

    guard let primaryEmotion = tags.first else {
        return "neutral"
    }

    return primaryEmotion.value
}
```

### Search Optimization

```swift
func generateSearchKeywords(for content: String) async throws -> [String] {
    let provider = ARCIntelligence.contentTaggingProvider()

    let tags = try await provider.generateTags(
        for: content,
        categories: [.topic, .object, .action],
        maxTags: 10
    )

    return tags
        .filter { $0.confidence >= 0.7 }
        .map { $0.value }
}
```

## Error Handling

Handle tagging errors appropriately:

```swift
do {
    let tags = try await provider.generateTags(
        for: text,
        categories: [.topic],
        maxTags: 5
    )
    // Use tags
} catch IntelligenceError.providerUnavailable {
    print("Tagging not available on this device")
} catch IntelligenceError.requestFailed(let reason) {
    print("Tagging failed: \(reason)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Testing

Use `MockContentTaggingProvider` for testing:

```swift
import ARCIntelligenceMocks

@Test("Generate topic tags")
func generateTopicTags() async throws {
    let mock = MockContentTaggingProvider(
        tagsToReturn: [
            ContentTag(value: "technology", category: .topic, confidence: 0.95),
            ContentTag(value: "programming", category: .topic, confidence: 0.90)
        ]
    )

    let tags = try await mock.generateTags(
        for: "Swift programming tutorial",
        categories: [.topic],
        maxTags: 5
    )

    #expect(tags.count == 2)
    #expect(tags[0].value == "technology")
}
```

Use category-specific tags:

```swift
let mock = MockContentTaggingProvider(
    tagsByCategory: [
        .topic: ["swift", "ios", "development"],
        .emotion: ["excited", "curious"],
        .action: ["coding", "learning"]
    ]
)
```

Use convenience methods:

```swift
// Standard test data
let standardMock = MockContentTaggingProvider.standard()

// Failing mock for error testing
let failingMock = MockContentTaggingProvider.failing(
    with: .requestFailed("Service unavailable")
)
```

## Best Practices

1. **Choose appropriate categories**: Only request categories relevant to your use case
2. **Set reasonable maxTags**: Too many tags may include less relevant results
3. **Filter by confidence**: Use confidence scores to filter quality tags
4. **Handle empty results**: Some text may not produce tags for certain categories
5. **Cache results**: Tag generation can be cached for repeated content
6. **Batch when possible**: Use batch processing for multiple texts

## See Also

- ``ContentTaggingProvider``
- ``ContentTag``
- ``TagCategory``
- <doc:Testing>
