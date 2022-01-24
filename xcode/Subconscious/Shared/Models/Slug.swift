//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/18/22.
//

import Foundation


/// A slug is a local path and ID for an entry
/// Currently this is just a typealias. In future we may give it a
/// distinct type.
typealias Slug = String

extension String {
    /// Slugify a string, returning a slug.
    func slugify() -> Slug? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return trimmed
            .lowercased()
            // Replace runs of one or more space with a single dash
            .replacingOccurrences(
                of: #"\s+"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            // Remove all non-slug characters
            .replacingOccurrences(
                of: #"[^a-zA-Z0-9_\-\/]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            .truncatingSafeFileNameLength()
            .ltrim(prefix: "/")
    }

    /// Slugify a string, returning a string.
    /// For now, this is just a proxy to toSlug.
    func slugifyString() -> String? {
        self.slugify()
    }
}

extension URL {
    /// Convert URL to a slug.
    /// In other words, return the last path component without the extension.
    func toSlug() -> Slug {
        self.deletingPathExtension().lastPathComponent
    }
}
