//
//  Entry.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// An entry is an envelope containing a slug and some corresponding contents
struct Entry<T>: Hashable, Identifiable
where T: Hashable
{
    var slug: Slug
    var id: Slug { slug }
    var contents: T
}

/// A Subtext entry is an Entry containing a SubtextMemo
typealias SubtextEntry = Entry<Memo<Subtext>>

extension FileStore {
    /// Read a subtext entry from a slug
    func read(_ slug: Slug) throws -> SubtextEntry {
        let memo: SubtextMemo = try read(String(describing: slug))
        return SubtextEntry(slug: slug, contents: memo)
    }

    /// Write a Subtext entry to its slug
    func write(_ entry: SubtextEntry) throws {
        try write(String(describing: entry.slug), memo: entry.contents)
    }
}
