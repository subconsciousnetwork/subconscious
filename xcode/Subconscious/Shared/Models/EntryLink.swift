//
//  EntryLink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

/// A EntryLink is a model that contains a title and slug description of a note
/// suitable for list views.
struct EntryLink: Hashable, Equatable, Identifiable {
    let slug: Slug
    let title: String
    let linkableTitle: String

    init(slug: Slug, title: String) {
        self.slug = slug
        self.title = Self.sanitizeTitle(title)
        let titleSlug = Slug(formatting: self.title)
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
