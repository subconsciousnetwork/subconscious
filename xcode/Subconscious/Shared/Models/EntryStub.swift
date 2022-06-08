//
//  EntryStub.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/12/22.
//

import Foundation

/// A EntryLink is a model that contains a title and slug description of a note
/// suitable for list views.
struct EntryStub:
    Hashable,
    Equatable,
    Identifiable,
    CustomDebugStringConvertible
{
    var link: EntryLink
    var excerpt: String
    var modified: Date

    init(
        link: EntryLink,
        excerpt: String,
        modified: Date
    ) {
        self.link = link
        self.excerpt = excerpt
        self.modified = modified
    }

    var slug: Slug { link.slug }
    var title: String { link.linkableTitle }
    var id: Slug { slug }
    var debugDescription: String {
        "Subconscious.EntryStub(\(slug))"
    }
}
