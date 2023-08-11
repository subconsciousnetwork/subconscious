//
//  MemoEditorDetailResponse.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
//

import Foundation

/// Response when reading info for memo editor detail from data source.
struct MemoEditorDetailResponse: Hashable {
    var saveState: SaveState
    var entry: MemoEntry
}

extension MemoEditorDetailResponse: CustomLogStringConvertible {
    var logDescription: String {
        "MemoEditorDetailResponse(\(entry.address))"
    }
}

extension FileFingerprint {
    init(_ detail: MemoEditorDetailResponse) {
        let text = String(describing: detail.entry.contents.body)
        self.init(
            slug: detail.entry.address.slug,
            modified: detail.entry.contents.modified,
            text: text
        )
    }
}
