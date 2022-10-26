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
    /// Get title or derive title from slug
    func titleOrDefault() -> String {
        contents.headers.title() ?? slug.toTitle()
    }

    /// Sets slug and title, using linkable title, to bring them in sync.
    mutating func setLink(_ link: EntryLink) {
        self.slug = link.slug
        self.contents.headers.title(link.linkableTitle)
    }

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

extension MemoData {
    init(_ entry: SubtextEntry) {
        self.init(
            headers: entry.contents.headers,
            body: entry.slug.toPath(ContentType.subtext.ext)
        )
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
