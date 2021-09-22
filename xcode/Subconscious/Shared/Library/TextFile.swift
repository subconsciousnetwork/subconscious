//
//  SubtextDocument.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/21/21.
import Foundation

/// A SubtextDocument together with a location for that document
struct TextFile: Hashable, Equatable, Identifiable {
    var url: URL
    var content: String
    var id: URL { url }
    var title: String { url.stem }

    init(
        url: URL,
        content: String
    ) {
        // Absolutize URL in order to allow it to function as an ID
        self.url = url.absoluteURL
        self.content = content
    }

    /// Open existing document
    init(url: URL) throws {
        // Absolutize URL in order to allow it to function as an ID
        self.url = url.absoluteURL
        self.content = try String(contentsOf: url, encoding: .utf8)
    }

    func write() throws {
        try content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
