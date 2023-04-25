//
//  Slug.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/27/23.
//

import Foundation

/// A type representing a valid slug (`/slug`)
public struct Slug:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let slugRegex = /([\w\d\-]+)(\/[\w\d\-]+)*/
    public static let profile = Slug("_profile_")!

    public static func < (lhs: Slug, rhs: Slug) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Attempt to sanitize a string into a "slug string"-a string that
    /// represents a valid slug.
    private static func format(_ string: String) -> String {
        // Strip all non-allowed characters
        let formatted = string.replacingOccurrences(
            of: #"[^\w\d\-\s]"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
        // Trim leading/trailing whitespace
        .trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace runs of one or more space with a single dash
        .replacingOccurrences(
            of: #"\s+"#,
            with: "-",
            options: .regularExpression,
            range: nil
        )
        .truncatingSafeFileNameLength()
        return formatted
    }
    
    public let description: String
    public let verbatim: String

    public var id: String { description }

    public var markup: String {
        "/\(description)"
    }
    
    public var verbatimMarkup: String {
        "/\(verbatim)"
    }
    
    public var isProfile: Bool {
        self == Slug.profile
    }
    
    /// Excludes "internal" slugs like `Slug.profile`
    public var isListable: Bool {
        !verbatim.hasPrefix("_")
    }
    
    /// Losslessly create a slug from a string.
    /// This requires that the string already be formatted like a
    /// valid slug.
    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.slugRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    /// Convert a string into a slug.
    /// This will sanitize the string as best it can to create a valid slug.
    public init?(formatting string: String) {
        self.init(Self.format(string))
    }

    /// Create a slug from a URL.
    ///
    /// Note this is lossless, so it will only support URLs that contain
    /// valid slug strings as paths.
    public init?(url: URL, relativeTo base: URL) {
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
        self.verbatim
            .replacingOccurrences(
                of: #"-"#,
                with: " ",
                range: nil
            )
            .capitalizingFirst()
    }

    /// Create relative path-like string from slug
    func toPath(_ ext: String) -> String {
        self.description.appendingPathExtension(ext)
    }
}

extension Slug {
    init?(fromPath path: String, withExtension ext: String) {
        guard let sluglike = path.deletingPathExtension(ext) else {
            return nil
        }
        self.init(sluglike)
    }
}

extension URL {
    /// Convert URL to a slug.
    /// In other words, return the last path component without the extension.
    func toSlug(relativeTo base: URL) -> Slug? {
        Slug(url: self, relativeTo: base)
    }
}

extension String {
    func toSlug() -> Slug? {
        Slug(formatting: self)
    }
}
