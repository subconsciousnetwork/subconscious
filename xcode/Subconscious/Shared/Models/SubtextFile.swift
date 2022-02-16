//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A Subtext DOM together with a location for that document
struct SubtextFile: Hashable, Equatable, Identifiable {
    var slug: Slug
    var dom: Subtext
    var content: String { dom.base }
    var id: Slug { slug }
    var title: String { dom.title() }
    var excerpt: String { dom.excerpt() }

    init(
        slug: Slug,
        content: String
    ) {
        self.slug = slug
        self.dom = Subtext(markup: content)
    }

    init(
        slug: Slug,
        dom: Subtext
    ) {
        self.slug = slug
        self.dom = dom
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

    func url(directory: URL) -> URL {
        self.slug.toURL(directory: directory, ext: "subtext")
    }

    /// Append additional Subtext to this file
    /// Returns a new instance
    func append(_ dom: Subtext) -> Self {
        var file = self
        file.dom = self.dom.append(dom)
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
}
