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
    var debugDescription: String {
        "Subconscious.EntryStub(\(slug))"
    }

    var slug: Slug
    var title: String
    var excerpt: String
    var modified: Date
    var id: Slug { slug }
}
