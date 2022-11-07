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
    CustomDebugStringConvertible,
    Codable
{
    let link: EntryLink
    let excerpt: String
    let modified: Date

    var slug: Slug { link.slug }
    var linkableTitle: String { link.linkableTitle }
    var id: Slug { slug }
    var debugDescription: String {
        "Subconscious.EntryStub(\(slug))"
    }
}
