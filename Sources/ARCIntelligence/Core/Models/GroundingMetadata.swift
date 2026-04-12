//
//  GroundingMetadata.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 12/04/2026.
//

import Foundation

/// Metadata from provider-level grounding (e.g. Google Search).
///
/// Contains the search queries executed by the provider and the web sources
/// cited in the grounded response. Not all providers support grounding —
/// `IntelligenceResponse.groundingMetadata` will be `nil` when grounding is
/// not available or was not requested.
public struct GroundingMetadata: Sendable, Equatable {
    /// Search queries the provider executed to ground its response.
    public let searchQueries: [String]

    /// Web sources cited in the grounded response.
    public let webSources: [WebSource]

    public init(searchQueries: [String] = [], webSources: [WebSource] = []) {
        self.searchQueries = searchQueries
        self.webSources = webSources
    }

    // MARK: - WebSource

    /// A single web source cited by the provider's grounding search.
    public struct WebSource: Sendable, Equatable {
        /// Human-readable title of the source page.
        public let title: String

        /// URI of the source page.
        public let uri: String

        public init(title: String, uri: String) {
            self.title = title
            self.uri = uri
        }
    }
}
