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
    /// The identity of the sphere this entry belongs to, if any
    var sphereIdentity: String?
    var slug: Slug
    var id: Slug { slug }
    var contents: T
}

/// A Subtext entry is an Entry containing a SubtextMemo
typealias MemoEntry = Entry<Memo>

extension MemoEntry {
    /// Sets slug and title, using linkable title, to bring them in sync.
    mutating func setLink(_ link: EntryLink) {
        self.slug = link.slug
        self.contents.title = link.linkableTitle
    }

    func url(directory: URL) -> URL {
        slug.toURL(directory: directory, ext: ContentType.subtext.fileExtension)
    }
    
    /// Merge two Subtext entries together.
    /// Headers are merged.
    /// `other` Subtext is appended to the end of `self` Subtext.
    func merge(_ that: MemoEntry) -> Self {
        var this = self
        this.contents.additionalHeaders = this.contents.additionalHeaders
            .merge(that.contents.additionalHeaders)
        let concatenated = "\(this.contents.body)\n\n\(that.contents.body)"
        this.contents.body = concatenated
        return this
    }
}

extension EntryLink {
    init(_ entry: MemoEntry) {
        self.init(
            slug: entry.slug,
            title: entry.contents.title
        )
    }
}

extension EntryStub {
    init(_ entry: MemoEntry) {
        self.link = EntryLink(entry)
        self.excerpt = entry.contents.excerpt()
        self.modified = entry.contents.modified
    }
}
