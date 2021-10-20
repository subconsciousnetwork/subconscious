//
//  ResultSet.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

struct ResultSet {
    var query: String = ""
    var slug: String = ""
    var entry: TextFile? = nil
    var backlinks: [TextFile] = []
}
