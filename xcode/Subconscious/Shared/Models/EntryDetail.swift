//
//  EntryDetail.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct EntryDetail: Hashable {
    var saveState: SaveState
    var entry: SubtextEntry
    var backlinks: [EntryStub] = []
    var slug: Slug {
        entry.slug
    }
}

extension EntryDetail: CustomLogStringConvertible {
    var logDescription: String {
        "EntryDetail(\(slug))"
    }
}

extension FileFingerprint {
    init(_ detail: EntryDetail) {
        let modified = detail.entry.contents.headers.modified() ?? Date.epoch
        let text = String(describing: detail.entry.contents.body)
        self.init(
            slug: detail.slug,
            modified: modified,
            text: text
        )
    }
}
