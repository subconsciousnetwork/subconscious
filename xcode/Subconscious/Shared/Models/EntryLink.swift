//
//  EntryLink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

/// A EntryLink contains a slug, title, and linkable title.
/// Linkable title is a title that is reducible to the slug,
/// e.g. when used as a wikilink.
struct EntryLink:
    Hashable,
    Equatable,
    Identifiable,
    CustomStringConvertible,
    Codable
{
    let slug: Slug
    let title: String
    let linkableTitle: String

    init(slug: Slug, title: String) {
        self.slug = slug
        let title = Self.sanitizeTitle(title)
        self.title = title
        let titleSlug = Slug(formatting: title)
        self.linkableTitle = (
            titleSlug != self.slug ?
            Self.sanitizeTitle(slug.toTitle()) :
            title
        )
    }

    /// Construct an EntryLink from a string.
    /// Slug is generated for string using lossy approach.
    init?(title: String) {
        let title = Self.sanitizeTitle(title)
        guard let slug = Slug(formatting: title) else {
            return nil
        }
        self.title = title
        self.linkableTitle = title
        self.slug = slug
    }

    /// Construct an EntryLink from a slug.
    /// Title is generated using `slug.toTitle()`.
    init(slug: Slug) {
        self.slug = slug
        let title = Self.sanitizeTitle(slug.toTitle())
        self.title = title
        self.linkableTitle = title
    }

    var id: Slug { slug }
    var description: String { linkableTitle }

    static func sanitizeTitle(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(
                of: #"\s"#,
                with: " ",
                options: .regularExpression
            )
    }
}
