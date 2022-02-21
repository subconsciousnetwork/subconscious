//
//  EntryLink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

/// A EntryLink is a model that contains a title and slug description of a note
/// suitable for list views.
struct EntryLink: Hashable, Identifiable {
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

    var id: Slug { slug }
}
