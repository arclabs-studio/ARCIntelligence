# ARCIntelligence Showcase

A complete example iOS app demonstrating all features of the ARCIntelligence package.

## Overview

This showcase app provides interactive examples of every major feature in ARCIntelligence, making it easy to understand how to integrate AI capabilities into your own applications.

## Features Demonstrated

### 1. Text Completions
- Generate AI completions with different configurations
- Preset configurations (Default, Factual, Creative)
- Custom temperature settings
- Token usage tracking
- Error handling

**Location**: `Views/CompletionsView.swift`

### 2. Streaming Responses
- Real-time token-by-token streaming
- Start/stop streaming control
- Progressive UI updates
- Cancellation support

**Location**: `Views/StreamingView.swift`

### 3. Conversations
- Multi-turn dialogue management
- Message history visualization
- Chat-style UI with message bubbles
- System prompt configuration
- Conversation clearing

**Location**: `Views/ConversationView.swift`

### 4. Utilities
- **Prompt Builder**: Construct structured prompts with system instructions, context, and queries
- **Token Counter**: Estimate token usage, check limits, and truncate text

**Location**: `Views/UtilitiesView.swift`

### 5. Settings & Configuration
- Switch between providers (Mock vs Foundation Models)
- Check provider availability
- View provider information
- Links to documentation

**Location**: `Views/SettingsView.swift`

## Requirements

- Xcode 16.0+
- iOS 17.0+ (for running the app)
- iOS 18.0+ (for Foundation Models features)

## Installation

### Option 1: Open in Xcode

1. Navigate to the Examples directory:
   ```bash
   cd Examples/ARCIntelligenceShowcase
   ```

2. Open the project:
   ```bash
   open ARCIntelligenceShowcase.xcodeproj
   ```

3. Select a simulator or device

4. Build and run (⌘R)

### Option 2: Use Swift Package Manager

The showcase app is configured to use the local ARCIntelligence package automatically.

## Project Structure

```
ARCIntelligenceShowcase/
├── ARCIntelligenceShowcaseApp.swift  # App entry point & AppState
├── ContentView.swift                  # Main navigation
└── Views/
    ├── CompletionsView.swift         # Text completion examples
    ├── StreamingView.swift           # Streaming examples
    ├── ConversationView.swift        # Conversation examples
    ├── UtilitiesView.swift           # Utilities demos
    ├── SettingsView.swift            # Settings & provider config
    └── AboutView.swift               # About page
```

## Key Concepts Demonstrated

### Provider Management

The app uses an `AppState` class to manage the current AI provider:

```swift
@StateObject private var appState = AppState()
```

This allows switching between providers without restarting the app.

### Mock Provider by Default

The app starts with a Mock provider to ensure it works immediately:

- No API keys required
- Works on all devices
- Fast and predictable responses
- Great for testing UI

### Foundation Models Support

Switch to Foundation Models in Settings to use real AI:

- On-device processing
- Privacy-first
- Requires iOS 18.0+
- No API costs

### MVVM Architecture

Each view has a corresponding ViewModel:

- `CompletionsViewModel`
- `StreamingViewModel`
- `ConversationViewModel`

This demonstrates best practices for SwiftUI apps.

### Error Handling

All examples include comprehensive error handling:

```swift
do {
    let response = try await provider.complete(...)
} catch {
    self.error = error.localizedDescription
}
```

## Usage Examples

### Text Completions

1. Open the app
2. Tap "Text Completions"
3. Enter a prompt (or use the default)
4. Select a configuration preset
5. Tap "Generate"
6. View the response and token count

### Streaming

1. Tap "Streaming Responses"
2. Enter a prompt
3. Tap "Start Streaming"
4. Watch tokens appear in real-time
5. Optionally tap "Stop" to cancel

### Conversations

1. Tap "Conversations"
2. Type a message in the input field
3. Tap send (arrow icon)
4. Continue the conversation
5. Tap trash icon to clear history

### Utilities

**Prompt Builder:**
1. Tap "Utilities"
2. Select "Prompt Builder" tab
3. Enter system instruction, context, and query
4. Tap "Build Prompt"
5. See the formatted result

**Token Counter:**
1. Select "Token Counter" tab
2. Enter or edit text
3. Tap "Count Tokens"
4. View token estimate and character count
5. Adjust token limit slider
6. See if text fits within limit

## Tips

### Testing Different Providers

1. Go to Settings
2. Select "Foundation Models" (requires iOS 18+)
3. Tap "Check Availability"
4. Return to examples to test with real AI

### Customizing Examples

The example code is designed to be easily modified:

- Change default prompts in ViewModels
- Adjust configurations
- Add new examples
- Modify UI layouts

### Learning the API

Each View demonstrates key ARCIntelligence concepts:

- **CompletionsView**: Basic `provider.complete()` usage
- **StreamingView**: Using `AsyncThrowingStream`
- **ConversationView**: `ConversationalAssistant` pattern
- **UtilitiesView**: `PromptBuilder` and `TokenCounter`

## Architecture Highlights

### Dependency Injection

Providers are injected via EnvironmentObject:

```swift
@EnvironmentObject var appState: AppState
```

This makes testing easy and follows SwiftUI best practices.

### Async/Await Throughout

All AI operations use Swift's modern concurrency:

```swift
Task {
    await viewModel.generate(provider: appState.currentProvider)
}
```

### Type Safety

The app leverages Swift's type system:

- Enums for provider types
- Protocols for provider interfaces
- Strongly typed configurations

## Extending the Showcase

Want to add more examples? Follow this pattern:

1. Create a new View in `Views/`
2. Create a corresponding ViewModel
3. Add navigation in `ContentView.swift`
4. Use the existing examples as templates

## Troubleshooting

### "Provider not available"

- Make sure you're using iOS 18+ for Foundation Models
- Check device compatibility
- Try switching to Mock provider in Settings

### Build errors

- Ensure Xcode 16+ is installed
- Clean build folder (⌘⇧K)
- Delete derived data

### Slow responses

- Mock provider has configurable delays
- Foundation Models depends on device performance
- Check network if using cloud providers (future)

## Resources

- [ARCIntelligence Documentation](../../README.md)
- [API Reference](../../Sources/ARCIntelligence/ARCIntelligence.docc/)
- [GitHub Repository](https://github.com/arclabs-studio/ARCIntelligence)

## License

This example app is part of ARCIntelligence and is released under the same MIT License.

---

**Built with ❤️ by ARC Labs Studio**
