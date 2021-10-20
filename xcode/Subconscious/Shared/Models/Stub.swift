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
    var title: String
    var slug: String

    init(title: String, slug: String) {
        self.title = title
        self.slug = slug
    }

    init(title: String) {
        self.title = title
        self.slug = Slashlink.slugify(title)
    }

    var id: String { slug }
}
