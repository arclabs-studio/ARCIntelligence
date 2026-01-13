# ARC Labs Studio - Coding Standards for ARCIntelligence

This document outlines the coding standards and best practices for the ARCIntelligence Swift package.

## Swift Version & Platform Requirements

- **Swift**: 6.0+
- **Platforms**: iOS 17.0+, macOS 14.0+
- **Architecture**: Clean Architecture with Protocol-Oriented Design
- **Concurrency**: Full Swift Concurrency support with strict checking enabled

## File Organization

### One Type Per File
- Each file should contain **exactly one** public type (class, struct, enum, protocol, actor)
- Private nested types are allowed within the same file
- File name must match the type name exactly (e.g., `IntelligenceProvider.swift` for `IntelligenceProvider` protocol)

### File Header Template
All files must include this header:
```swift
//
//  [FileName].swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on [Date].
//
```

### Directory Structure
```
Sources/
├── ARCIntelligence/
│   ├── Core/
│   │   ├── Protocols/     # All protocol definitions
│   │   ├── Models/        # Data models and DTOs
│   │   └── Errors/        # Error types
│   ├── Providers/         # Provider implementations
│   ├── UseCases/          # Business logic & use cases
│   └── Utilities/         # Helper utilities
└── ARCIntelligenceMocks/  # Mock implementations for testing
```

## Swift 6 Concurrency Requirements

### Sendable Compliance
- **All public types** must conform to `Sendable`
- Use `actor` for types with mutable shared state
- Use `@Sendable` closures where required
- Avoid `@unchecked Sendable` unless absolutely necessary (document why)

### Async/Await
- Use `async/await` for all asynchronous operations
- Prefer `AsyncThrowingStream` for streaming data
- Use `Task` for concurrent operations
- Enable strict concurrency checking in all targets

## Code Organization

### MARK Comments
Use MARK comments to organize code sections:
```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Protocol Conformance
```

### Access Control
- Use `public` for external API
- Use `internal` for package-internal code (default)
- Use `private` for implementation details
- Use `fileprivate` sparingly (prefer `private`)

## Documentation

### DocC Documentation
All public APIs require documentation comments:
```swift
/// Brief one-line summary.
///
/// Extended description with usage details and important notes.
///
/// - Parameters:
///   - parameter1: Description of parameter1
///   - parameter2: Description of parameter2
/// - Returns: Description of return value
/// - Throws: Description of errors that can be thrown
///
/// - Note: Additional notes if needed
/// - Important: Critical information
public func exampleMethod(parameter1: String, parameter2: Int) async throws -> String {
    // Implementation
}
```

### Documentation Language
- All documentation must be in **English**
- Use clear, concise language
- Include usage examples for complex APIs
- Document thread-safety guarantees
- Explain error conditions

## Error Handling

### Custom Errors
- Use `enum` with `LocalizedError` conformance
- Provide clear, actionable error messages
- Include context in error cases (associated values)
- Handle all error cases explicitly

### Error Propagation
```swift
// Preferred: Let errors propagate
func riskyOperation() async throws -> Result {
    try await performOperation()
}

// Avoid: Silent failures
func riskyOperation() async -> Result? {
    try? await performOperation()  // Don't do this
}
```

## Testing

### Test Coverage
- Aim for **100% coverage** on core protocols and models
- Write unit tests for all public APIs
- Use mocks for external dependencies
- Test error conditions explicitly

### Test Organization
```swift
import Testing
@testable import ARCIntelligence
import ARCIntelligenceMocks

@Suite("Feature Tests")
struct FeatureTests {

    @Test("Test case description")
    func testCaseMethod() async throws {
        // Given
        // When
        // Then
        #expect(condition)
    }
}
```

## Naming Conventions

### General Rules
- Use descriptive names that convey intent
- Prefer clarity over brevity
- Use camelCase for variables and methods
- Use PascalCase for types

### Protocols
- Use noun names for capability protocols: `IntelligenceProvider`, `ConversationProvider`
- Avoid `-able` or `-ible` suffixes unless truly appropriate

### Methods
- Start with verbs: `generate`, `fetch`, `calculate`, `send`
- Use `is`/`has` prefixes for Boolean properties
- Use `did`/`will`/`should` for delegate methods

### Properties
- Use nouns for properties: `displayName`, `version`, `configuration`
- Avoid redundant prefixes (e.g., use `name`, not `providerName` in `Provider` context)

## Code Quality

### SwiftLint
- All code must pass SwiftLint with zero warnings
- Use the provided `.swiftlint.yml` configuration
- Custom rules are defined for ARC Labs standards

### Code Style
```swift
// Preferred: Clear and explicit
let result = try await provider.complete(
    prompt: userInput,
    configuration: .default
)

// Avoid: Overly clever or compressed
let r=try await p.complete(prompt:i,configuration:.default)
```

### Constants
```swift
// Preferred: Named constants
private enum Constants {
    static let defaultTimeout: TimeInterval = 30.0
    static let maxRetries = 3
}

// Avoid: Magic numbers
try await fetchData(timeout: 30.0)  // What does 30.0 mean?
```

## Protocol Design

### Protocol Composition
- Keep protocols focused and single-purpose
- Use protocol composition for complex capabilities
- Provide default implementations in extensions where appropriate

### Protocol Requirements
```swift
public protocol Example: Sendable {
    // Required properties
    var id: String { get }

    // Required methods
    func performAction() async throws

    // Optional methods (via extension with default implementation)
}

extension Example {
    // Default implementation
    func performAction() async throws {
        // Default behavior
    }
}
```

## Performance Considerations

### Lazy Evaluation
- Use `lazy` for expensive computed properties
- Avoid unnecessary work in initializers
- Cache expensive computations when appropriate

### Memory Management
- Avoid retain cycles with `[weak self]` or `[unowned self]`
- Use value types (struct) for immutable data
- Use reference types (class, actor) for shared mutable state

## Security

### Data Privacy
- Never log sensitive data (API keys, user content)
- Use secure storage for credentials
- Sanitize user input before processing

### Input Validation
```swift
public func process(input: String) async throws {
    guard !input.isEmpty else {
        throw IntelligenceError.invalidRequest("Input cannot be empty")
    }

    guard input.count <= maxInputLength else {
        throw IntelligenceError.invalidRequest("Input exceeds maximum length")
    }

    // Process validated input
}
```

## Version Control

### Commits
- Write clear, descriptive commit messages
- Use conventional commits format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation
  - `test:` for tests
  - `refactor:` for refactoring
  - `chore:` for maintenance

### Branches
- Use descriptive branch names
- Follow pattern: `feature/description`, `fix/description`
- Keep branches focused on single tasks

## Dependencies

### External Dependencies
- Minimize external dependencies
- Prefer standard library when possible
- Document why each dependency is needed
- Pin to specific versions in Package.swift

### Internal Dependencies
- Use protocols to define dependencies
- Inject dependencies through initializers
- Avoid singletons (prefer dependency injection)

## Deprecation

### Marking Deprecated APIs
```swift
@available(*, deprecated, message: "Use newMethod() instead")
public func oldMethod() {
    // Implementation
}
```

### Migration Path
- Always provide a migration path
- Document the replacement in deprecation message
- Maintain deprecated APIs for at least one major version

## Professional Standards

### Code Review
- All code must be reviewed before merging
- Address all review comments
- Maintain professional and constructive feedback

### Quality Checklist
Before submitting code, verify:
- [ ] Compiles without warnings
- [ ] All tests pass
- [ ] SwiftLint passes
- [ ] Documentation is complete
- [ ] No TODO comments remain
- [ ] File headers are correct
- [ ] One type per file
- [ ] 100% test coverage for core features

---

## Questions or Clarifications?

For questions about these standards, consult:
1. Swift API Design Guidelines: https://swift.org/documentation/api-design-guidelines/
2. Swift Concurrency Documentation: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
3. DocC Documentation: https://www.swift.org/documentation/docc/

---

**ARC Labs Studio** - Building intelligent, reliable, and elegant Swift packages.
