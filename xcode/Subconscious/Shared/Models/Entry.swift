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
    var contents: Memo<T>
}

extension Entry {
    /// Mend blessed headers, providing them with default values
    mutating func mendHeaders(
        modified: Date = Date.now,
        created: Date = Date.now
    ) {
        contents.headers.fallback(
            name: "Title",
            value: slug.toTitle()
        )
        contents.headers.fallback(
            name: "Modified",
            value: String.from(modified)
        )
        contents.headers.fallback(
            name: "Created",
            value: String.from(created)
        )
    }
    
    /// Get title or derive title from slug
    func titleOrDefault() -> String {
        contents.headers.title() ?? slug.toTitle()
    }

    /// Sets slug and title, using linkable title, to bring them in sync.
    mutating func setLink(_ link: EntryLink) {
        self.slug = link.slug
        self.contents.headers.title(link.linkableTitle)
    }
}

/// A Subtext entry is an Entry containing a SubtextMemo
typealias SubtextEntry = Entry<Subtext>

extension SubtextEntry {
    /// Create a Subtext Entry with blessed headers,
    /// and providing default values.
    init(
        link: EntryLink,
        modified: Date = Date.now,
        created: Date = Date.now,
        contents: Subtext
    ) {
        self.slug = link.slug
        self.contents = SubtextMemo(
            modified: modified,
            created: created,
            title: link.title,
            contents: contents
        )
    }
}

extension SubtextEntry {
    func url(directory: URL) -> URL {
        slug.toURL(directory: directory, ext: ContentType.subtext.ext)
    }
    
    /// Merge two Subtext entries together.
    /// Headers are merged.
    /// `other` Subtext is appended to the end of `self` Subtext.
    func merge(_ other: SubtextEntry) -> Self {
        var this = self
        this.contents.headers = this.contents.headers.merge(
            other.contents.headers
        )
        let subtext = this.contents.body.appending(other.contents.body)
        this.contents.body = subtext
        return this
    }
}

extension FileStore {
    /// Read a subtext entry from a slug
    func read(slug: Slug) throws -> SubtextEntry {
        let memo: SubtextMemo = try read(String(describing: slug))
        return SubtextEntry(slug: slug, contents: memo)
    }

    /// Write a Subtext entry to its slug
    func write(entry: SubtextEntry) throws {
        try write(String(describing: entry.slug), memo: entry.contents)
    }
}

extension EntryLink {
    init(_ entry: SubtextEntry) {
        self.init(
            slug: entry.slug,
            title: entry.titleOrDefault()
        )
    }
}

extension EntryStub {
    init(_ entry: SubtextEntry) {
        self.link = EntryLink(slug: entry.slug, title: entry.titleOrDefault())
        self.excerpt = entry.contents.body.excerpt()
        self.modified = entry.contents.headers.modifiedOrDefault()
    }
}
