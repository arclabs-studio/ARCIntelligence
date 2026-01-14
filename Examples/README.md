# ARCIntelligence Examples

This directory contains example applications demonstrating how to use the ARCIntelligence package.

## Available Examples

### ARCIntelligenceShowcase

A complete iOS app showcasing all features of ARCIntelligence.

**Features Demonstrated:**
- ✅ Text completions with different configurations
- ✅ Real-time streaming responses
- ✅ Multi-turn conversations
- ✅ Guided generation (structured output)
- ✅ Tool calling and function execution
- ✅ Content tagging and analysis
- ✅ Session transcripts
- ✅ Prompt builder utility
- ✅ Token counter utility
- ✅ Provider switching (Mock vs Foundation Models)
- ✅ Error handling patterns
- ✅ SwiftUI integration
- ✅ MVVM architecture

**Quick Start:**

```bash
cd Examples/ARCIntelligenceShowcase
open ARCIntelligenceShowcase.xcodeproj
```

Then select a simulator and press Cmd+R to build and run.

**Read more:** [ARCIntelligenceShowcase README](ARCIntelligenceShowcase/README.md)

## Running Examples

Each example is a standalone Xcode project that references ARCIntelligence as a local package dependency. This follows ARC Labs Studio standards for example apps.

### Requirements

- Xcode 16.0 or later
- iOS 17.0+ deployment target
- macOS 14.0+ (for Mac apps)
- iOS 26+ (for Foundation Models features)

### Installation

1. Navigate to the example directory
2. Open the `.xcodeproj` file in Xcode
3. Select a simulator or device
4. Build and run (Cmd+R)

No additional setup required - the examples automatically reference the local ARCIntelligence package through Xcode's Swift Package Manager integration.

## Learning Path

We recommend exploring the examples in this order:

1. **ARCIntelligenceShowcase** - Start here for a complete overview
   - Begin with Text Completions
   - Move to Streaming
   - Try Conversations
   - Explore Utilities

## Example Structure

Each example follows this structure:

```
ExampleName/
├── ExampleName.xcodeproj/     # Xcode project
├── ExampleName/               # Source code
│   ├── App.swift             # App entry point
│   ├── Views/                # SwiftUI views
│   └── ...                   # Supporting files
└── README.md                 # Example-specific documentation
```

## Code Patterns

All examples demonstrate:

- ✅ Protocol-based provider usage
- ✅ Async/await patterns
- ✅ Error handling
- ✅ SwiftUI integration
- ✅ Testing with mocks
- ✅ Best practices

## Contributing Examples

Have an interesting use case? Contribute an example!

1. Create a new directory in `Examples/`
2. Add a standalone Xcode project
3. Reference ARCIntelligence as a local package
4. Include a comprehensive README
5. Submit a pull request

## Support

- [ARCIntelligence Documentation](../README.md)
- [API Reference](../Sources/ARCIntelligence/ARCIntelligence.docc/)
- [GitHub Issues](https://github.com/arclabs-studio/ARCIntelligence/issues)

---

**Examples maintained by ARC Labs Studio**
