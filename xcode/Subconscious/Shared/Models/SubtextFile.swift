//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A SubtextDocument together with a location for that document
struct SubtextFile: Hashable, Equatable, Identifiable {
    var url: URL
    var dom: Subtext
    var content: String { dom.base }
    var id: URL { url }
    var title: String { dom.title() }
    var excerpt: String { dom.excerpt() }
    var slug: Slug { url.stem }

    init(
        url: URL,
        content: String
    ) {
        // Absolutize URL in order to allow it to function as an ID
        self.url = url.absoluteURL
        self.dom = Subtext(markup: content)
    }

    /// Open existing document
    init(url: URL) throws {
        self.init(
            url: url,
            content: try String(contentsOf: url, encoding: .utf8)
        )
    }

    func write() throws {
        try content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
