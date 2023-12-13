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
    // Is the excerpt shorter than the full body of the entry?
    let isTruncated: Bool
    let modified: Date
    var color: NoteColor? = nil

    var id: Slashlink { address }
    var debugDescription: String {
        "Subconscious.EntryStub(\(address))"
    }
    
    func withAddress(_ address: Slashlink) -> Self {
        return Self(
            did: did,
            address: address,
            excerpt: excerpt,
            isTruncated: isTruncated,
            modified: modified
        )
    }
    
    func toPeer() -> Peer {
        address.petname.map(Peer.petname) ?? Peer.did(did)
    }
}

extension EntryLink {
    init(_ stub: EntryStub) {
        self.init(address: stub.address, title: stub.excerpt.title())
    }
}
