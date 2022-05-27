//
//  EntryDetail.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct EntryDetail {
    var saveState: SaveState
    var entry: SubtextFile
    var backlinks: [EntryStub] = []
    var slug: Slug {
        entry.slug
    }
}
