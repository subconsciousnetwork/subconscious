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
    let address: Slashlink
    let excerpt: String
    let modified: Date

    var id: Slashlink { address }
    var debugDescription: String {
        "Subconscious.EntryStub(\(address))"
    }
}

extension EntryLink {
    init(_ stub: EntryStub) {
        self.init(address: stub.address, title: stub.excerpt.title())
    }
}
