//
//  Entry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

struct DraftEntry: Identifiable, Hashable, Equatable {
    var title: String {
        dom.excerpt().derivingTitle()
    }
    var content: String {
        dom.renderMarkup()
    }
    var id = UUID()
    var dom: Subtext2

    init(content: String) {
        self.dom = Subtext2(markup: content)
    }

    init(dom: Subtext2) {
        self.dom = dom
    }
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

    /// Basic initializer
    init(url: URL, dom: Subtext2) {
        self.url = url.absoluteURL
        self.dom = dom
    }

    /// Initialize from draft
    init(url: URL, entry: DraftEntry) {
        self.init(
            url: url,
            dom: Subtext2(markup: entry.content)
        )
    }

    /// Initialize with URL and string
    init(url: URL, content: String) {
        self.init(
            url: url,
            dom: Subtext2(markup: content)
        )
        self.url = url.absoluteURL
        self.dom = Subtext2(markup: content)
    }

    /// Initialize entry file wrapper by reading URL
    init(url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        self.init(
            url: url,
            content: content
        )
    }
    
    /// Initialize with from draft, synthesizing URL
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
            self.init(
                url: url,
                dom: entry.dom
            )
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
    var entry: FileEntry? = nil
    var backlinks: [FileEntry] = []
}
