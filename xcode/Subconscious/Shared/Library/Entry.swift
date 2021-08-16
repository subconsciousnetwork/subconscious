//
//  Entry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

struct DraftEntry: Identifiable, Hashable, Equatable {
    var id = UUID()
    var title: String {
        Subtext2(markup: content).excerpt().derivingTitle()
    }
    var content: String
}

/// Represents an entry on the file system.
/// Contains an entry, and a URL for the file in which the entry is stored.
struct FileEntry: Identifiable, Hashable, Equatable {
    var id: URL { url }
    var title: String {
        dom.excerpt().derivingTitle()
    }
    var content: String {
        dom.renderMarkup()
    }
    var url: URL
    var dom: Subtext2

    init(url: URL, entry: DraftEntry) {
        self.url = url
        self.dom = Subtext2(markup: entry.content)
    }

    /// Initialize entry file wrapper by reading URL
    init(url: URL) throws {
        self.url = url
        let content = try String(contentsOf: url, encoding: .utf8)
        self.dom = Subtext2(markup: content)
    }

    /// Initialize with URL and string
    init(url: URL, content: String) {
        self.url = url
        self.dom = Subtext2(markup: content)
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
            self.dom = Subtext2(markup: entry.content)
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

extension FileEntry: StringKeyed {
    var key: String { title }
}

struct EntryResults: Equatable {
    var fileEntries: [FileEntry] = []
    var transcludes = SlugIndex<FileEntry>()
}
