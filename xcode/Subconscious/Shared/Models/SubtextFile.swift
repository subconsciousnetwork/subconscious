//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A Subtext DOM together with a location for that document
struct SubtextFile: Hashable, Equatable, Identifiable {
    var slug: Slug
    var envelope: SubtextEnvelope

    init(
        slug: Slug,
        content: String
    ) {
        self.slug = slug
        self.envelope = SubtextEnvelope.parse(markup: content)
    }

    init(
        slug: Slug,
        dom: SubtextEnvelope
    ) {
        self.slug = slug
        self.envelope = dom
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

    var content: String { String(describing: envelope) }
    var id: Slug { slug }

    func url(directory: URL) -> URL {
        self.slug.toURL(directory: directory, ext: "subtext")
    }

    /// Append additional Subtext to this file
    /// Returns a new instance
    func append(_ dom: SubtextEnvelope) -> Self {
        var file = self
        file.envelope = self.envelope.append(dom)
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
        try content.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )
    }

    /// Return linkable title.
    /// Use header value if present, otherwise derive from slug.
    func title() -> String {
        EntryLink(
            slug: slug,
            title: envelope.headers["Title"] ?? ""
        )
        .toLinkableTitle()
    }

    func excerpt() -> String {
        envelope.body.excerpt()
    }

    /// Sets required headers.
    /// Also removes duplicate headers (we discourage these).
    func mendHeaders() -> Self {
        var headers = self.envelope.headers

        headers["Content-Type"] = "text/subtext"

        let titleValue = EntryLink(
            slug: slug,
            title: headers["Title"] ?? ""
        )
        .toLinkableTitle()
        headers["Title"] = titleValue

        // headers["Modified"] = modified.ISO8601Format()

        var this = self
        this.envelope.headers = headers
        return this
    }
}

extension EntryLink {
    init(_ entry: SubtextFile) {
        self.slug = entry.slug
        self.title = entry.envelope.headers["Title"] ?? ""
    }
}

//
//extension EntryStub {
//    init(_ entry: SubtextFile) {
//        self.slug = entry.slug
//        self.title = entry.envelope.title()
//        self.excerpt = entry.envelope.body.excerpt()
//        self.modified = Date.now
//    }
//}
