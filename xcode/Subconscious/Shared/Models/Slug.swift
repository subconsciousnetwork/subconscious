//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/18/22.
//

import Foundation

/// A slug is a normalized identifier (basically "words-and-dashes")
struct Slug:
    Identifiable,
    Hashable,
    Equatable,
    Comparable,
    LosslessStringConvertible,
    Codable
{
    /// Compare slugs by alpha
    static func < (lhs: Slug, rhs: Slug) -> Bool {
        lhs.id < rhs.id
    }

    /// Sanitize a string into a "slug string"-a string into a string that can
    /// be losslessly converted to and from a Slug.
    ///
    /// If a valid slug string cannot be produced, returns nil.
    ///
    /// If you need a value to truly be a slug, use the Slug constructor.
    static func format(_ string: String) -> String? {
        let slugString = string
            // Strip all non-allowed characters
            .replacingOccurrences(
                of: #"[^a-zA-Z0-9_\-\/\s]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            // Trim leading/trailing whitespace
            .trimmingCharacters(in: .whitespacesAndNewlines)
            // Then trim leading/trailing slashes
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
            // Replace runs of one or more space with a single dash
            .replacingOccurrences(
                of: #"\s+"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            // Replace all instances of two or more consecutive slashes
            // with a single slash.
            .replacingOccurrences(
                of: #"/+"#,
                with: "/",
                options: .regularExpression,
                range: nil
            )
            .truncatingSafeFileNameLength()
        guard !slugString.isEmpty else {
            return nil
        }
        return slugString
    }

    let id: String
    var description: String { id }

    /// Losslessly create a slug from a string.
    /// This requires that the string already be formatted like a
    /// sanitized slug, including being lowercased.
    init?(_ string: String) {
        guard let id = Self.format(string) else {
            return nil
        }
        // Check that sanitization was lossless.
        guard id == string else {
            return nil
        }
        self.id = id
    }

    /// Convert a string into a slug.
    /// This will sanitize the string as best it can to create a valid slug.
    init?(formatting string: String) {
        guard let id = Self.format(string) else {
            return nil
        }
        self.id = id
    }

    /// Create a slug from a URL.
    ///
    /// Note this is lossless, so it will only support URLs that contain
    /// valid slug strings as paths.
    init?(url: URL, relativeTo base: URL) {
        // NOTE: it is extremely important that we call relativizingPath
        // WITHOUT calling `url.deletePathExtension()`.
        // This is because `url.relativizingPath()` calls
        // `.standardizedFileURL` to resolve symlinks.
        // However, if there is not a file extension, `.standardizedFileURL`
        // will not recognize the URL as a file URL and will not
        // resolve symlinks.
        //
        // Instead, we relativize the path, get back a string, and then
        // use our custom String extension to remove the file extension.
        //
        // Issue: https://github.com/gordonbrander/subconscious/issues/57
        //
        // 2022-01-27 Gordon Brander
        guard let path = url.relativizingPath(relativeTo: base) else {
            return nil
        }
        self.init(path.deletingPathExtension())
    }

    /// Create a URL from this slug
    func toURL(directory: URL, ext: String) -> URL {
        directory.appendingFilename(name: self.id, ext: ext)
    }

    /// Create a nice title-like string from a slug
    func toTitle() -> String {
        // Remove all non-slug characters
        self.description
            .replacingOccurrences(
                of: #"-"#,
                with: " ",
                range: nil
            )
            .capitalizingFirst()
    }
}

extension Slug {
    /// Create a slashlink (markup string) from slug
    /// https://github.com/gordonbrander/subtext
    func toSlashlink() -> String {
        "/\(self.description)"
    }
}

extension URL {
    /// Convert URL to a slug.
    /// In other words, return the last path component without the extension.
    func toSlug(relativeTo base: URL) -> Slug? {
        Slug(url: self, relativeTo: base)
    }
}
