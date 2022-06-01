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
    var body: String

    /// Initialize SubtextFile properties directly
    init(
        slug: Slug,
        headers: HeaderIndex,
        body: String
    ) {
        self.slug = slug
        self.headers = headers
        self.body = body
    }

    /// Initialize SubtextFile with blessed headers
    init(
        slug: Slug,
        title: String,
        modified: Date,
        created: Date,
        body: String
    ) {
        self.slug = slug
        let link = EntryLink(slug: slug, title: title)
        self.headers = HeaderIndex(
            [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Title", value: link.linkableTitle),
                Header(name: "Modified", value: modified.ISO8601Format()),
                Header(name: "Created", value: created.ISO8601Format()),
            ]
        )
        self.body = body
    }

    /// Initialize SubtextFile by parsing body and headers from `content`
    init(
        slug: Slug,
        content: String
    ) {
        self.slug = slug
        let envelope = HeadersEnvelope.parse(markup: content)
        self.headers = HeaderIndex(envelope.headers)
        self.body = String(envelope.body)
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
        Subtext.parse(markup: body)
    }

    var description: String {
        "\(headers)\(body)"
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
        file.body = body.appending("\n").appending(other.body)
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

    /// Set slug and title from an entry link.
    /// Sets a linkable title, falling back to title derived from slug
    /// if title is not linkable.
    mutating func setSlugAndTitle(_ link: EntryLink) {
        self.slug = link.slug
        self.headers["Title"] = link.linkableTitle
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

    /// Mend "blessed" headers, providing them with sensible default values
    func mendingHeaders(
        modified: Date = Date.now
    ) -> Self {
        var this = self
        this.headers["Content-Type"] = "text/subtext"
        this.headers.setDefault(name: "Title", value: slug.toTitle())
        let iso = modified.ISO8601Format()
        this.headers.setDefault(name: "Modified", value: iso)
        this.headers.setDefault(name: "Created", value: iso)
        return this
    }

    func title() -> String {
        headers["Title"] ?? slug.toTitle()
    }

    func modified() -> Date {
        guard
            let dateString = headers["Modified"],
            let date = try? Date(dateString, strategy: .iso8601)
        else {
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }

    func modified(_ date: Date) -> Self {
        var this = self
        this.headers["Modified"] = date.ISO8601Format()
        return this
    }

    func created() -> Date {
        guard
            let dateString = headers["Created"],
            let date = try? Date(dateString, strategy: .iso8601)
        else {
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }

    func created(_ date: Date) -> Self {
        var this = self
        this.headers["Created"] = date.ISO8601Format()
        return this
    }

    func excerpt() -> String {
        dom.excerpt()
    }
}

extension EntryLink {
    init(_ entry: SubtextFile) {
        self.init(
            slug: entry.slug,
            title: entry.headers["Title"] ?? ""
        )
    }
}


extension EntryStub {
    init(_ entry: SubtextFile) {
        self.slug = entry.slug
        self.title = entry.title()
        self.excerpt = entry.excerpt()
        self.modified = entry.modified()
    }
}
