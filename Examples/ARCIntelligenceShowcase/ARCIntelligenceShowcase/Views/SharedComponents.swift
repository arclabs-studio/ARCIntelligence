//
//  SharedComponents.swift
//  ARCIntelligenceShowcase
//
//  Created by ARC Labs Studio on 21/03/2026.
//

import SwiftUI

// MARK: - Unavailable Feature View

struct UnavailableFeatureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Feature Unavailable")
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}
