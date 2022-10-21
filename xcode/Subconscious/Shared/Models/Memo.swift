//
//  Memo.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A "reified" memo who's bodypart has been loaded and decoded
struct Memo<T>: Hashable
where T: Hashable
{
    var headers: Headers
    var body: T
}

extension Memo {
    /// Create a Memo with blessed headers
    init(
        modified: Date,
        created: Date,
        title: String,
        contents: T
    ) {
        self.headers = Headers(
            contentType: ContentType.subtext.rawValue,
            modified: modified,
            created: created,
            title: title
        )
        self.body = contents
    }
}

typealias SubtextMemo = Memo<Subtext>
