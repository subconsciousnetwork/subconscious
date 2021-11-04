//
//  Stub.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

/// A Stub is a model that contains a short description of a note
/// suitable for list views.
struct Stub: Hashable, Identifiable {
    var slug: String
    var title: String

    init(slug: String, title: String) {
        self.slug = slug
        self.title = title
    }

    init(title: String) {
        self.title = title
        self.slug = Slashlink.slugify(title)
    }

    var id: String { slug }
}
