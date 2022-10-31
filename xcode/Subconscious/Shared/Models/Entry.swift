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
        created: Date = Date.now,
        modified: Date = Date.now,
        body: Subtext
    ) {
        self.slug = link.slug
        self.contents = SubtextMemo(
            contentType: ContentType.subtext,
            created: created,
            modified: modified,
            title: link.title,
            body: body
        )
    }
}

extension SubtextEntry {
    /// Sets slug and title, using linkable title, to bring them in sync.
    mutating func setLink(_ link: EntryLink) {
        self.slug = link.slug
        self.contents.title = link.linkableTitle
    }

    func url(directory: URL) -> URL {
        slug.toURL(directory: directory, ext: ContentType.subtext.ext)
    }
    
    /// Merge two Subtext entries together.
    /// Headers are merged.
    /// `other` Subtext is appended to the end of `self` Subtext.
    func merge(_ that: SubtextEntry) -> Self {
        var this = self
        this.contents.other = this.contents.other.merge(that.contents.other)
        let subtext = this.contents.body.appending(that.contents.body)
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
            title: entry.contents.title
        )
    }
}

extension EntryStub {
    init(_ entry: SubtextEntry) {
        self.link = EntryLink(entry)
        self.excerpt = entry.contents.body.excerpt()
        self.modified = entry.contents.modified
    }
}
