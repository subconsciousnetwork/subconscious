//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/18/22.
//

import Foundation

/// A slug is a normalized identifier (basically "words-and-dashes")
struct Slug: Identifiable, Hashable, Equatable, LosslessStringConvertible {
    let id: String
    var description: String { id }

    /// Create a slug from a string.
    init?(_ string: String) {
        // Trim whitespace and leading/trailing slashes
        let trimmed = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else {
            return nil
        }
        self.id = trimmed.lowercased()
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
    }

    /// Create a slug from a URL.
    ///
    /// Note this is lossy, since Slugs support a subset of what URLs support.
    /// In other words, you can create a slug from a URL, but round-trip
    /// creating a URL from a slug may not result in the same URL.
    init?(url: URL, relativeTo base: URL) {
        guard let path = url
            .deletingPathExtension()
            .relativizingPath(relativeTo: base)
        else {
            return nil
        }
        self.init(path)
    }

    /// Create a URL from this slug
    func toURL(directory: URL, ext: String) -> URL {
        directory.appendingFilename(name: self.id, ext: ext)
    }
}

extension String {
    /// Slugify a string, returning a slug.
    func slugify() -> Slug? {
        Slug(self)
    }

    /// Slugify a string, returning a string.
    /// For now, this is just a proxy to toSlug.
    func slugifyString() -> String? {
        self.slugify()?.description
    }
}

extension URL {
    /// Convert URL to a slug.
    /// In other words, return the last path component without the extension.
    func toSlug(relativeTo base: URL) -> Slug? {
        Slug(url: self, relativeTo: base)
    }
}
