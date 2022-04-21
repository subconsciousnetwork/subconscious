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
    var slug: Slug
    var title: String

    init(slug: Slug, title: String) {
        self.slug = slug
        self.title = title
    }

    /// Construct an EntryLink from a string.
    /// Slug is generated for string using lossy approach.
    init?(title: String) {
        guard let slug = Slug(formatting: title) else {
            return nil
        }
        self.title = title
        self.slug = slug
    }

    /// Construct an EntryLink from a slug.
    /// Title is generated using `slug.toTitle()`.
    init(slug: Slug) {
        self.slug = slug
        self.title = slug.toTitle()
    }

    var id: Slug { slug }

    /// Returns a nice-name string that will format to a valid
    /// slug for this entry.
    func toLinkableTitle() -> String {
        let titleSlug = Slug(formatting: self.title)
        // If title slug matches actual slug, then we can use title as the
        // nicename for the wikilink. This is better than sentence-ifying
        // the slug, because it lets us include things like apostrophes,
        // special case capitalization, etc.
        if titleSlug == self.slug {
            return self.title
        }
        return self.slug.toTitle()
    }
}
