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

    init?(title: String) {
        if let slug = title.slugify() {
            self.title = title
            self.slug = slug
        } else {
            return nil
        }
    }

    var id: Slug { slug }
}
