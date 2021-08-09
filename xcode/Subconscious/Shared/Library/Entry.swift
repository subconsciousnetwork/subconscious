//
//  Entry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

struct DraftEntry: Identifiable, Hashable, Equatable, StringKeyed {
    var key: String { title }
    var id = UUID()
    var content: String
}

extension DraftEntry {
    var title: String {
        Subtext.excerpt(markup: content).derivingTitle()
    }
    var dom: Subtext {
        Subtext(markup: content)
    }
}

/// Represents an entry on the file system.
/// Contains an entry, and a URL for the file in which the entry is stored.
struct FileEntry: Identifiable, Hashable, Equatable {
    var id: URL { url }
    var url: URL
    var content: String

    init(url: URL, entry: DraftEntry) {
        self.url = url
        self.content = entry.content
    }

    /// Initialize entry file wrapper by reading URL
    init(url: URL) throws {
        self.url = url
        self.content = try String(contentsOf: url, encoding: .utf8)
    }

    /// Initialize with URL and string
    init(url: URL, content: String) {
        self.url = url
        self.content = content
    }

    /// Initialize with entry, synthesizing URL
    init?(entry: DraftEntry) {
        let name = entry.title.toFilename()
        if
            let documentsURL = FileManager.default.documentDirectoryUrl,
            let url = FileManager.default.findUniqueFilename(
                at: documentsURL,
                name: name,
                ext: "subtext"
            )
        {
            self.url = url
            self.content = entry.content
        } else {
            return nil
        }
    }

    func write() throws {
        try content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}

extension FileEntry {
    var title: String {
        Subtext.excerpt(markup: content).derivingTitle()
    }
    var dom: Subtext {
        Subtext(markup: content)
    }
}

extension FileEntry: StringKeyed {
    var key: String { title }
}

struct EntryResults: Equatable {
    var fileEntries: [FileEntry] = []
    var transcludes = SlugIndex<FileEntry>()
}
