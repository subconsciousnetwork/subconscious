//
//  Memo.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A "reified" memo who's bodypart has been loaded and decoded
/// We have a few required header fields that we also represent as fields of
/// the struct.
struct Memo<T>: Hashable
where T: Hashable
{
    var contentType: ContentType
    var created: Date
    var modified: Date
    var title: String
    var other: Headers
    var body: T

    /// Get combined headers
    var headers: Headers {
        Headers(
            contentType: self.contentType,
            created: self.created,
            modified: self.modified,
            title: self.title
        )
        .merge(other)
    }

    /// Create a Memo with blessed headers
    init(
        contentType: ContentType,
        created: Date,
        modified: Date,
        title: String,
        other: Headers = [],
        body: T
    ) {
        self.contentType = contentType
        self.created = created
        self.modified = modified
        self.title = title
        self.other = other
        self.body = body
    }
}

typealias SubtextMemo = Memo<Subtext>
