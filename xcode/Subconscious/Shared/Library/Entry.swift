//
//  TextEntry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

struct Entry: Identifiable, Hashable, Equatable {
    var title: String {
        Subtext.excerpt(markup: content)
            .firstPseudoSentence
            .truncatingByWord(characters: 120)
    }
    var dom: Subtext {
        Subtext(markup: content)
    }
    var id = UUID()
    var content: String
}

/// Represents an entry on the file system.
/// Contains an entry, and a URL for the file in which the entry is stored.
struct EntryFile: Identifiable, Hashable, Equatable {
    var id: URL { url }
    var url: URL
    var entry: Entry

    init(url: URL, entry: Entry) {
        self.url = url
        self.entry = entry
    }

    /// Initialize entry file wrapper by reading URL
    init(url: URL) throws {
        self.url = url
        self.entry = try Entry(
            content: String(contentsOf: url, encoding: .utf8)
        )
    }

    /// Initialize with URL and string
    init(url: URL, content: String) {
        self.url = url
        self.entry = Entry(content: content)
    }

    /// Initialize with entry, synthesizing URL
    init?(entry: Entry) {
        let name = Slug.toFilename(entry.title)
        if
            let documentsURL = FileManager.default.documentDirectoryUrl,
            let url = FileManager.default.findUniqueFilename(
                at: documentsURL,
                name: name,
                ext: "subtext"
            )
        {
            self.url = url
            self.entry = entry
        } else {
            return nil
        }
    }

    func write() throws {
        try entry.content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
