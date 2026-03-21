//
//  ContentTaggingView.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 21/03/2026.
//

import ARCIntelligence
import SwiftUI

struct ContentTaggingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ContentTaggingViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if appState.contentTaggingProvider == nil {
                    UnavailableFeatureView(message: "Content tagging requires Foundation Models (on-device). Switch to Foundation Models in Settings.")
                } else {
                    inputSection
                    categorySection
                    generateButton
                    if !viewModel.tags.isEmpty {
                        tagsSection
                            .transition(.opacity)
                    }
                    if let error = viewModel.error {
                        ErrorView(message: error)
                            .transition(.opacity)
                    }
                }
            }
        }
        .navigationTitle("Content Tagging")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: viewModel.tags.isEmpty)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text to Analyze")
                .font(.headline)

            TextEditor(text: $viewModel.inputText)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1))
        }
        .padding()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(TagCategory.allCases, id: \.self) { category in
                    CategoryToggle(category: category,
                                   isSelected: viewModel.selectedCategories.contains(category)) {
                        viewModel.toggleCategory(category)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var generateButton: some View {
        Button {
            Task {
                if let provider = appState.contentTaggingProvider {
                    await viewModel.generateTags(provider: provider)
                }
            }
        } label: {
            HStack {
                if viewModel.isTagging {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "tag.fill")
                }
                Text(viewModel.isTagging ? "Tagging..." : "Generate Tags")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.isTagging || viewModel.inputText.isEmpty || viewModel.selectedCategories.isEmpty)
        .padding(.horizontal)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)
                .padding(.horizontal)

            ForEach(TagCategory.allCases, id: \.self) { category in
                let categoryTags = viewModel.tags.filter { $0.category == category }
                if !categoryTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(category.color)

                        FlowLayout(spacing: 8) {
                            ForEach(categoryTags) { tag in
                                TagChip(tag: tag, color: category.color)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Category Toggle

private struct CategoryToggle: View {
    let category: TagCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? category.color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: ContentTag
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.value)
                .font(.caption)

            if tag.confidence < 1.0 {
                Text(String(format: "%.0f%%", tag.confidence * 100))
                    .font(.caption2)
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width + spacing > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        _ = maxWidth
    }
}

// MARK: - TagCategory Extensions

extension TagCategory {
    fileprivate var displayName: String {
        switch self {
        case .topic: "Topics"
        case .action: "Actions"
        case .object: "Objects"
        case .emotion: "Emotions"
        }
    }

    fileprivate var color: Color {
        switch self {
        case .topic: .blue
        case .action: .green
        case .object: .orange
        case .emotion: .purple
        }
    }
}

// MARK: - View Model

@MainActor
@Observable final class ContentTaggingViewModel {
    var inputText = "I love hiking through the mountains on a sunny afternoon. The fresh air and beautiful views make me feel truly alive and at peace."
    var selectedCategories: Set<TagCategory> = Set(TagCategory.allCases)
    var isTagging = false
    var tags: [ContentTag] = []
    var error: String?

    func toggleCategory(_ category: TagCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func generateTags(provider: any ContentTaggingProvider) async {
        isTagging = true
        error = nil
        tags = []

        do {
            tags = try await provider.generateTags(for: inputText,
                                                   categories: Array(selectedCategories),
                                                   maxTags: 5)
        } catch {
            self.error = error.localizedDescription
        }

        isTagging = false
    }
}

#Preview {
    NavigationView {
        ContentTaggingView()
            .environment(AppState())
    }
}
