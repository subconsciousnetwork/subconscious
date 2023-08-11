//
//  MemoDetailResponse.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/14/23.
//

import Foundation

/// Response when reading info for a view-only memo detail from data source.
struct MemoDetailResponse: Hashable {
    var entry: MemoEntry
}

extension MemoDetailResponse: CustomLogStringConvertible {
    var logDescription: String {
        "MemoDetailResponse(\(entry.address))"
    }
}
