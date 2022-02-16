//
//  EntryDetail.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct EntryDetail {
    var slug: Slug
    var entry: SaveEnvelope<SubtextFile>
    var backlinks: [EntryStub] = []
}
