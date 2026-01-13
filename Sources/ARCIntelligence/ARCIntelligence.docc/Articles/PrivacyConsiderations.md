# Privacy Considerations

Understand the privacy implications of using different AI providers.

## Overview

When integrating AI capabilities into your app, privacy is a critical consideration. Different providers have different privacy characteristics, and this guide helps you make informed decisions.

## Privacy Spectrum

### On-Device Processing

**Providers**: Foundation Models, Local LLMs

**Privacy Level**: ⭐⭐⭐⭐⭐ Maximum

**Characteristics:**
- User data never leaves the device
- No network transmission
- No third-party data access
- Complete user control
- No logging or monitoring possible

```swift
// Maximum privacy: everything stays on device
let provider = ARCIntelligence.foundationModels(
    configuration: FoundationModelsConfiguration(
        onDeviceOnly: true  // Critical: no cloud fallback
    )
)
```

### Cloud Processing

**Providers**: OpenAI, Anthropic (future), custom cloud APIs

**Privacy Level**: ⭐⭐ to ⭐⭐⭐ (depends on provider)

**Characteristics:**
- Data transmitted over network
- Processed on third-party servers
- Subject to provider's privacy policy
- May be logged or used for training
- Requires user consent in many jurisdictions

```swift
// Lower privacy: data sent to cloud
// (Hypothetical - not yet implemented)
let provider = OpenAIProvider(apiKey: "...")
```

## Privacy Decision Matrix

| Use Case | Recommended Provider | Rationale |
|----------|---------------------|-----------|
| Medical records | On-Device Only | HIPAA compliance required |
| Financial data | On-Device Preferred | PCI-DSS considerations |
| Personal messages | On-Device Preferred | High sensitivity |
| Public content | Cloud Acceptable | Already public information |
| General assistance | On-Device First | Privacy by default |

## Data Flow Analysis

### Foundation Models Flow

```
User Input
    ↓
Your App
    ↓
Foundation Models Provider
    ↓
Apple Neural Engine (on-device)
    ↓
Response (never leaves device)
    ↓
Your App
    ↓
User
```

**Privacy Impact**: ✅ Zero - data never leaves device

### Cloud Provider Flow

```
User Input
    ↓
Your App
    ↓
Cloud Provider (e.g., OpenAI)
    ↓
Network Transmission (TLS encrypted)
    ↓
Third-Party Servers
    ↓
Processing (may be logged)
    ↓
Network Transmission (TLS encrypted)
    ↓
Your App
    ↓
User
```

**Privacy Impact**: ⚠️ High - data sent to third party

## Best Practices

### 1. Default to Privacy

Start with the most private option:

```swift
func createProvider(userPreference: ProviderPreference = .privacy) -> IntelligenceProvider {
    switch userPreference {
    case .privacy:
        // Default: maximum privacy
        return ARCIntelligence.foundationModels(
            configuration: .privacy  // On-device only
        )

    case .power:
        // User explicitly chose power over privacy
        return createCloudProvider()

    case .balanced:
        // Try privacy first, fallback to cloud if needed
        let onDevice = ARCIntelligence.foundationModels()
        return Task { await onDevice.isAvailable() }.result.value ?? createCloudProvider()
    }
}
```

### 2. User Consent

Always get consent before sending data to cloud:

```swift
func processWithAI(_ text: String, provider: IntelligenceProvider) async throws -> String {
    // Check if this is a cloud provider
    if isCloudProvider(provider) {
        let consent = await requestUserConsent(
            message: "This will send your data to \(provider.displayName). Continue?"
        )

        guard consent else {
            throw IntelligenceError.requestFailed("User denied consent")
        }
    }

    let response = try await provider.complete(
        prompt: text,
        configuration: .default
    )

    return response.content
}

private func isCloudProvider(_ provider: IntelligenceProvider) -> Bool {
    // On-device providers
    let onDeviceProviders = [
        "com.arclabs.intelligence.foundation",
        "com.arclabs.intelligence.mock"
    ]

    return !onDeviceProviders.contains(provider.id)
}
```

### 3. Data Minimization

Only send necessary data:

```swift
func summarizeDocument(_ document: Document) async throws -> String {
    // ❌ Bad: Send entire document including metadata
    let fullData = document.jsonRepresentation
    let response = try await provider.complete(prompt: fullData, configuration: .default)

    // ✅ Good: Send only necessary content
    let essentialContent = document.textContent  // Just the text, no metadata
    let sanitizedContent = removePII(from: essentialContent)  // Remove PII
    let response = try await provider.complete(
        prompt: "Summarize: \(sanitizedContent)",
        configuration: .default
    )

    return response.content
}

private func removePII(from text: String) -> String {
    // Remove email addresses
    var sanitized = text.replacingOccurrences(
        of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#,
        with: "[EMAIL]",
        options: .regularExpression
    )

    // Remove phone numbers
    sanitized = sanitized.replacingOccurrences(
        of: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,
        with: "[PHONE]",
        options: .regularExpression
    )

    // Remove credit card numbers
    sanitized = sanitized.replacingOccurrences(
        of: #"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"#,
        with: "[CARD]",
        options: .regularExpression
    )

    return sanitized
}
```

### 4. Transparency

Be transparent about data usage:

```swift
struct AISettings {
    enum AIProvider: String, CaseIterable {
        case onDevice = "On-Device (Private)"
        case cloud = "Cloud (Requires Internet)"

        var privacyDescription: String {
            switch self {
            case .onDevice:
                return "Your data never leaves your device. Maximum privacy."
            case .cloud:
                return "Data is sent securely to our AI provider. See privacy policy."
            }
        }

        var privacyLevel: PrivacyLevel {
            switch self {
            case .onDevice: return .maximum
            case .cloud: return .moderate
            }
        }
    }
}

// In your settings UI
ForEach(AIProvider.allCases, id: \.self) { provider in
    VStack(alignment: .leading) {
        Text(provider.rawValue)
            .font(.headline)

        Text(provider.privacyDescription)
            .font(.caption)
            .foregroundColor(.secondary)

        PrivacyIndicator(level: provider.privacyLevel)
    }
}
```

### 5. Audit Logging

Log privacy-sensitive operations (locally):

```swift
actor PrivacyAuditLog {
    private var entries: [AuditEntry] = []

    func log(_ entry: AuditEntry) {
        entries.append(entry)

        // Keep only recent entries
        if entries.count > 1000 {
            entries.removeFirst()
        }
    }

    func getEntries() -> [AuditEntry] {
        entries
    }
}

struct AuditEntry {
    let timestamp: Date
    let provider: String
    let operation: String
    let dataClassification: DataClassification
    let userConsent: Bool
}

enum DataClassification {
    case public
    case internal
    case confidential
    case restricted
}

// Usage
let auditLog = PrivacyAuditLog()

await auditLog.log(AuditEntry(
    timestamp: Date(),
    provider: provider.id,
    operation: "completion",
    dataClassification: .internal,
    userConsent: true
))
```

## Regulatory Compliance

### GDPR (Europe)

Requirements when using cloud providers:

1. **User Consent**: Explicit opt-in required
2. **Right to Delete**: Support data deletion requests
3. **Data Portability**: Export user data on request
4. **Privacy by Default**: Use on-device processing by default

```swift
class GDPRCompliantAI {
    func configure(userConsent: GDPRConsent) -> IntelligenceProvider {
        guard userConsent.cloudProcessingAllowed else {
            // No consent: use on-device only
            return ARCIntelligence.foundationModels(configuration: .privacy)
        }

        // Consent given: can use cloud
        return createCloudProvider()
    }
}

struct GDPRConsent {
    let cloudProcessingAllowed: Bool
    let dataRetentionAgreed: Bool
    let thirdPartySharing: Bool
    let timestamp: Date
}
```

### HIPAA (Healthcare - US)

For medical data:

1. **On-Device Only**: Strongly recommended
2. **Business Associate Agreement**: Required if using cloud
3. **Encryption**: End-to-end encryption required
4. **Audit Logs**: Comprehensive logging required

```swift
class HIPAACompliantAI {
    func createProvider() -> IntelligenceProvider {
        // HIPAA: On-device processing only
        return ARCIntelligence.foundationModels(
            configuration: FoundationModelsConfiguration(
                onDeviceOnly: true  // Critical for HIPAA
            )
        )
    }

    func processPatientData(_ data: PatientData) async throws -> String {
        // Verify on-device processing
        let provider = createProvider()

        guard provider.id.contains("foundation") else {
            throw IntelligenceError.providerNotConfigured(
                "Only on-device providers allowed for HIPAA data"
            )
        }

        // Process with maximum privacy
        let response = try await provider.complete(
            prompt: data.summary,
            configuration: .default
        )

        // Log access (required for HIPAA)
        await auditLog.log(
            user: data.userId,
            action: "AI processing",
            provider: provider.id
        )

        return response.content
    }
}
```

### CCPA (California)

Requirements:

1. **Disclosure**: Inform users about AI data usage
2. **Opt-Out**: Allow opting out of cloud processing
3. **Data Sale**: Don't sell AI-processed data

```swift
struct CCPACompliance {
    static func showPrivacyNotice() -> String {
        """
        Our app uses AI to provide enhanced features. You can choose between:

        1. On-Device Processing: Your data never leaves your device (recommended)
        2. Cloud Processing: Faster and more powerful, but data is sent to our provider

        You can change this setting at any time in Privacy Settings.

        We never sell your data or AI interactions to third parties.
        """
    }

    static func handleOptOut() -> IntelligenceProvider {
        // User opted out of cloud: use on-device only
        return ARCIntelligence.foundationModels(configuration: .privacy)
    }
}
```

## Privacy Patterns

### Pattern 1: Privacy Fallback Chain

```swift
func getProvider() async -> IntelligenceProvider {
    // Try on-device first
    let onDevice = ARCIntelligence.foundationModels()
    if await onDevice.isAvailable() {
        return onDevice
    }

    // Fallback: ask user for cloud consent
    let consent = await askCloudConsent()
    if consent {
        return createCloudProvider()
    }

    // No consent: use mock (limited functionality)
    return MockIntelligenceProvider()
}
```

### Pattern 2: Data Classification

```swift
enum DataSensitivity {
    case public      // Can use any provider
    case internal    // Prefer on-device
    case confidential // On-device only
    case restricted   // No AI processing allowed
}

func processData(_ data: String, sensitivity: DataSensitivity) async throws -> String {
    let provider: IntelligenceProvider

    switch sensitivity {
    case .public:
        provider = getPreferredProvider()  // User's choice

    case .internal:
        provider = ARCIntelligence.foundationModels()  // On-device preferred

    case .confidential:
        provider = ARCIntelligence.foundationModels(configuration: .privacy)  // On-device only

    case .restricted:
        throw IntelligenceError.invalidRequest("AI processing not allowed for this data")
    }

    return try await provider.complete(prompt: data, configuration: .default).content
}
```

### Pattern 3: Anonymization

```swift
func processWithAnonymization(_ text: String) async throws -> String {
    // Replace identifiable information with placeholders
    let placeholders: [String: String] = [:]
    let anonymized = anonymize(text, placeholders: &placeholders)

    // Process anonymized text
    let response = try await provider.complete(
        prompt: anonymized,
        configuration: .default
    )

    // Restore original information
    return deanonymize(response.content, placeholders: placeholders)
}

private func anonymize(_ text: String, placeholders: inout [String: String]) -> String {
    var anonymized = text

    // Replace names
    let namePattern = #"\b[A-Z][a-z]+ [A-Z][a-z]+\b"#
    // Replace with placeholders and store mapping

    return anonymized
}
```

## See Also

- <doc:ChoosingAProvider>
- <doc:BestPractices>
- ``FoundationModelsProvider``
- ``FoundationModelsConfiguration``
