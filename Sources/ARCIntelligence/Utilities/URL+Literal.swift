//
//  URL+Literal.swift
//  ARCIntelligence
//
//  Created by ARC Labs Studio on 18/02/2026.
//

import Foundation

// MARK: - StaticString initializer

extension URL {
    /// Creates a `URL` from a compile-time string literal.
    ///
    /// Because `StaticString` can only be supplied as a literal, the validity
    /// of the URL is guaranteed by the programmer at the point of call.
    /// A `preconditionFailure` is raised at runtime if the literal is somehow
    /// not a valid URL, making the programming error immediately visible.
    ///
    /// Use this instead of `URL(string: "...")!` to avoid SwiftLint
    /// `force_unwrapping` violations for hardcoded base URLs.
    ///
    /// ```swift
    /// private static let baseURL = URL(literal: "https://api.openai.com")
    /// ```
    init(literal: StaticString) {
        let string = "\(literal)"
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid URL literal: \(literal)")
        }
        self = url
    }
}
