//
//  AboutView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 18/11/2025.
//

import SwiftUI
import ARCIntelligence

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo/Icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("ARCIntelligence")
                        .font(.title)
                        .bold()

                    Text("Version \(ARCIntelligence.version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Description
                Text("Professional AI capabilities for iOS and macOS applications")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Divider()
                    .padding(.horizontal)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.headline)

                    FeatureRow(
                        icon: "sparkles",
                        title: "Text Completions",
                        description: "Generate AI-powered text completions"
                    )

                    FeatureRow(
                        icon: "wave.3.right",
                        title: "Streaming",
                        description: "Real-time token-by-token streaming"
                    )

                    FeatureRow(
                        icon: "bubble.left.and.bubble.right",
                        title: "Conversations",
                        description: "Multi-turn dialogue management"
                    )

                    FeatureRow(
                        icon: "lock.shield",
                        title: "Privacy First",
                        description: "On-device processing with Foundation Models"
                    )

                    FeatureRow(
                        icon: "swift",
                        title: "Swift 6",
                        description: "Modern concurrency with async/await"
                    )

                    FeatureRow(
                        icon: "testtube.2",
                        title: "Testing",
                        description: "Comprehensive mocks for easy testing"
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Architecture
                VStack(alignment: .leading, spacing: 12) {
                    Text("Architecture")
                        .font(.headline)

                    Text("ARCIntelligence uses a protocol-based architecture that makes it easy to swap AI providers without changing your code.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ArchitectureLayer(name: "Protocols", color: .blue)
                        ArchitectureLayer(name: "Providers", color: .green)
                        ArchitectureLayer(name: "Use Cases", color: .orange)
                        ArchitectureLayer(name: "Utilities", color: .purple)
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Credits
                VStack(spacing: 12) {
                    Text("Created by")
                        .font(.headline)

                    Text("ARC Labs Studio")
                        .font(.title3)
                        .bold()

                    Link("Visit arclabs.studio", destination: URL(string: "https://arclabs.studio")!)
                        .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Architecture Layer

struct ArchitectureLayer: View {
    let name: String
    let color: Color

    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 4)

            Text(name)
                .font(.subheadline)

            Spacer()
        }
        .frame(height: 32)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
