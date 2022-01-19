//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A SubtextDocument together with a location for that document
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

    /// Open existing document
    init?(slug: Slug, directory: URL) {
        let url = directory.appendingFilename(name: slug, ext: "subtext")
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
        directory.appendingFilename(name: slug, ext: "subtext")
    }

    func write(directory: URL) throws {
        try content.write(
            to: url(directory: directory),
            atomically: true,
            encoding: .utf8
        )
    }
}
