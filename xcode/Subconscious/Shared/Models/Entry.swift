//
//  Entry.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// An entry is an envelope containing a slug and some corresponding contents
struct Entry<T>: Hashable, Identifiable
where T: Hashable
{
    var address: Slashlink
    var id: String { address.description }
    var contents: T
}

/// A Subtext entry is an Entry containing a SubtextMemo
typealias MemoEntry = Entry<Memo>

extension EntryLink {
    init(_ entry: MemoEntry) {
        self.init(
            address: entry.address,
            title: entry.contents.title()
        )
    }
}

extension EntryStub {
    init(_ entry: MemoEntry, did: Did) {
        let excerpt = entry.contents.excerpt()
        
        self.address = entry.address
        self.excerpt = Subtext(markup: entry.contents.excerpt())
        self.modified = entry.contents.modified
        self.did = did
        self.headers = entry.contents.wellKnownHeaders()
    }
}
