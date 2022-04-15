//
//  Wikilink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/14/22.
//

import Foundation

/// An immutable struct representing a wikilink.
/// Text corresponds to a slug in 1:1 relationship.
/// Conversion from text to slug is lossy, so these fields are immutable, and
/// derived from each other.
struct EntryWikilink: Hashable, Equatable, Identifiable, CustomStringConvertible {
    let slug: Slug
    let text: String

    /// Construct a Wikilink from text
    init?(text: String) {
        guard let slug = Slug(formatting: text) else {
            return nil
        }
        self.slug = slug
        self.text = text
    }

    /// Construct a wikilink from a slug
    init(slug: Slug) {
        self.slug = slug
        self.text = slug.toSentence()
    }

    var description: String {
        text
    }

    var id: Slug {
        slug
    }

    /// As markup string
    var markup: String {
        String(describing: Markup.Wikilink(text: text))
    }
}
