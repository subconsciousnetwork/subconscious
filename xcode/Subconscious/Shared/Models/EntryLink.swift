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
    /// Title is generated using `slug.toSentence()`.
    init(slug: Slug) {
        self.slug = slug
        self.title = slug.toSentence()
    }

    var id: Slug { slug }
}

extension Markup.Wikilink {
    /// Create wiklink markup from this entry link
    init(_ link: EntryLink) {
        let titleSlug = Slug(formatting: link.title)
        // If title slug matches actual slug, then we can use title as the
        // nicename for the wikilink. This is better than sentence-ifying
        // the slug, because it lets us include things like apostrophes,
        // special case capitalization, etc.
        if titleSlug == link.slug {
            self.init(text: link.title)
        }
        // Otherwise, sentence-ify the slug
        else {
            self.init(text: link.slug.toSentence())
        }
    }
}
