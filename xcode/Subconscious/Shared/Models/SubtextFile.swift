//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A Subtext DOM together with a location for that document
struct SubtextFile:
    Hashable, Identifiable, CustomStringConvertible
{
    var slug: Slug
    var headers: HeaderIndex
    var content: String

    init(
        slug: Slug,
        content: String
    ) {
        self.slug = slug
        let envelope = HeadersEnvelope.parse(markup: content)
        self.headers = HeaderIndex(envelope.headers)
        self.content = String(envelope.body)
    }

    init(
        slug: Slug,
        headers: HeaderIndex,
        dom: Subtext
    ) {
        self.slug = slug
        self.headers = headers
        self.content = String(describing: dom)
    }

    /// Open existing document
    init?(slug: Slug, directory: URL) {
        let url = slug.toURL(directory: directory, ext: "subtext")
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            self.init(
                slug: slug,
                content: content
            )
        } else {
            return nil
        }
    }

    var dom: Subtext {
        Subtext.parse(markup: content)
    }

    var description: String {
        "\(headers)\(content)"
    }

    var id: Slug { slug }
    var size: Int {
        description.lengthOfBytes(using: .utf8)
    }

    func url(directory: URL) -> URL {
        self.slug.toURL(directory: directory, ext: "subtext")
    }

    /// Append additional Subtext to this file
    /// Returns a new instance
    func merge(_ other: SubtextFile) -> Self {
        var file = self
        file.headers = headers.merge(other.headers)
        file.content = content.appending("\n").appending(other.content)
        return file
    }

    func write(directory: URL) throws {
        let fileURL = self.url(directory: directory)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let body = String(describing: self)
        try body.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )
    }

    var title: String {
        headers["Title"] ?? slug.toTitle()
    }

    var modified: Date {
        get {
            guard
                let dateString = headers["Modified"],
                let date = try? Date(dateString, strategy: .iso8601)
            else {
                return Date(timeIntervalSince1970: 0)
            }
            return date
        }
        set {
            headers["Modified"] = newValue.ISO8601Format()
        }
    }

    var created: Date {
        get {
            guard
                let dateString = headers["Created"],
                let date = try? Date(dateString, strategy: .iso8601)
            else {
                return Date(timeIntervalSince1970: 0)
            }
            return date
        }
        set {
            headers["Created"] = newValue.ISO8601Format()
        }
    }

    var excerpt: String {
        get {
            dom.excerpt()
        }
    }

    func timestamped(
        _ date: Date = Date.now
    ) -> Self {
        var this = self
        let iso = date.ISO8601Format()
        this.headers["Modified"] = iso
        this.headers.setDefault(
            name: "Created",
            value: iso
        )
        return this
    }

    /// Set slug and title from an entry link.
    /// Sets a linkable title, falling back to title derived from slug
    /// if title is not linkable.
    mutating func setSlugAndTitle(_ link: EntryLink) {
        self.slug = link.slug
        self.headers["Title"] = link.toLinkableTitle()
    }

    /// Updates slug and title, deriving linkable title from entry link
    /// - Returns new SubtextFile
    func slugAndTitle(_ link: EntryLink) -> Self {
        var this = self
        this.setSlugAndTitle(link)
        return this
    }

    /// Updates the slug and title, deriving both from a title string
    /// - Returns new SubtextFile
    func slugAndTitle(_ title: String) -> Self? {
        guard let link = EntryLink(title: title) else {
            return nil
        }
        var this = self
        this.setSlugAndTitle(link)
        return this
    }

    /// Updates the slug and title, deriving both from a slug
    /// - Returns new SubtextFile
    func slugAndTitle(_ slug: Slug) -> Self {
        let link = EntryLink(slug: slug)
        var this = self
        this.setSlugAndTitle(link)
        return this
    }
}

extension EntryLink {
    init(_ entry: SubtextFile) {
        self.slug = entry.slug
        self.title = entry.headers["Title"] ?? ""
    }
}


extension EntryStub {
    init(_ entry: SubtextFile) {
        self.slug = entry.slug
        self.title = entry.title
        self.excerpt = entry.excerpt
        self.modified = entry.modified
    }
}
