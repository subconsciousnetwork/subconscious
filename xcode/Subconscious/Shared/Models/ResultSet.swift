//
//  ResultSet.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct ResultSet {
    var query: String = ""
    var slug: Slug = ""
    var entry: SubtextFile? = nil
    var backlinks: [EntryStub] = []
}
