//
//  Entry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

/// Represents an entry on the file system.
/// Contains an entry, and a URL for the file in which the entry is stored.
struct TextFile: Identifiable, Hashable, Equatable {
    var id: URL { url }
    var url: URL
    var name: String
    var content: String
 
    /// Basic initializer
    init(
        url: URL,
        content: String
    ) {
        self.url = url.absoluteURL
        self.name = url.stem
        self.content = content
    }

    /// File initializer
    init(url: URL) throws {
        self.url = url
        self.name = url.stem
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

struct TextFileResults: Equatable {
    var entry: TextFile? = nil
    var backlinks: [TextFile] = []
}
