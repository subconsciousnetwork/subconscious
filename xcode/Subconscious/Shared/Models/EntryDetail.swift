//
//  EntryDetail.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct EntryDetail: Hashable {
    var saveState: SaveState
    var entry: SubtextFile
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
        self.init(
            slug: detail.slug,
            modified: detail.entry.modified(),
            text: detail.entry.body
        )
    }
}
