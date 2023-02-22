//
//  EntryDetail.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct EntryDetail: Hashable {
    var saveState: SaveState
    var entry: MemoEntry
    var backlinks: [EntryStub] = []
}

extension EntryDetail: CustomLogStringConvertible {
    var logDescription: String {
        "EntryDetail(\(entry.address))"
    }
}

extension FileFingerprint {
    init(_ detail: EntryDetail) {
        let text = String(describing: detail.entry.contents.body)
        self.init(
            slug: detail.entry.address.slug,
            modified: detail.entry.contents.modified,
            text: text
        )
    }
}
