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
    let did: Did
    let address: Slashlink
    let excerpt: Subtext
    let modified: Date

    var id: Slashlink { address }
    var debugDescription: String {
        "Subconscious.EntryStub(\(address))"
    }
    
    func withAddress(_ address: Slashlink) -> Self {
        return Self(
            did: did,
            address: address,
            excerpt: excerpt,
            modified: modified
        )
    }
}

extension EntryLink {
    init(_ stub: EntryStub) {
        // TODO: find a nicer signature
        self.init(address: stub.address, title: stub.excerpt.blocks.first?.body().toString().title() ?? "")
    }
}
