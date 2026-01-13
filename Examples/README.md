# ARCIntelligence Examples

This directory contains example applications demonstrating how to use the ARCIntelligence package.

## Available Examples

### ARCIntelligenceShowcase

A complete iOS app showcasing all features of ARCIntelligence.

**Features Demonstrated:**
- ✅ Text completions with different configurations
- ✅ Real-time streaming responses
- ✅ Multi-turn conversations
- ✅ Prompt builder utility
- ✅ Token counter utility
- ✅ Provider switching (Mock vs Foundation Models)
- ✅ Error handling patterns
- ✅ SwiftUI integration
- ✅ MVVM architecture

**Quick Start:**

```bash
cd ARCIntelligenceShowcase
open ARCIntelligenceShowcase.xcodeproj
```

Then build and run in Xcode.

**Read more:** [ARCIntelligenceShowcase README](ARCIntelligenceShowcase/README.md)

## Running Examples

Each example is a standalone Xcode project that includes ARCIntelligence as a local package dependency.

### Requirements

- Xcode 16.0 or later
- iOS 17.0+ deployment target
- macOS 14.0+ (for Mac apps)

### Installation

1. Navigate to the example directory
2. Open the `.xcodeproj` file
3. Build and run

No additional setup required - the examples automatically reference the local ARCIntelligence package.

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
