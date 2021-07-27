//
//  TextEntry.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

public struct Entry: Identifiable, Hashable, Equatable {
    public var title: String {
        Subtext.excerpt(markup: content)
            .firstPseudoSentence
            .truncatingByWord(characters: 120)
    }
    public var dom: Subtext {
        Subtext(markup: content)
    }
    public var id = UUID()
    public var content: String
}

/// Represents an entry on the file system.
/// Contains an entry, and a URL for the file in which the entry is stored.
public struct EntryFile: Identifiable, Hashable, Equatable {
    public var id: URL { url }
    public var url: URL
    public var entry: Entry

    public init(url: URL, entry: Entry) {
        self.url = url
        self.entry = entry
    }

    /// Initialize entry file wrapper by reading URL
    public init(url: URL) throws {
        self.url = url
        self.entry = try Entry(
            content: String(contentsOf: url, encoding: .utf8)
        )
    }

    /// Initialize with URL and string
    public init(url: URL, content: String) {
        self.url = url
        self.entry = Entry(content: content)
    }

    /// Initialize with entry, synthesizing URL
    public init?(entry: Entry) {
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
            self.entry = entry
        } else {
            return nil
        }
    }

    public func write() throws {
        try entry.content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}

public struct EntryResults {
    /// An index of entries.
    public struct Index {
        private(set) var index: [String: EntryFile]

        public init(_ entryFiles: [EntryFile] = []) {
            self.index = entryFiles.toDictionary(key: { entryFile in
                entryFile.entry.title.toSlug()
            })
        }

        public func like(_ title: String) -> EntryFile? {
            let slug = title.toSlug()
            return index[slug]
        }

        /// Given an array of wiklink strings, returns a set of EntryFiles corresponding to the links.
        /// Strings are normalized with `toSlug()` making this a kind of 1:1 fuzzy match without ranking.
        public func pluck(_ titles: [String]) -> Index {
            Index(titles.compactMap(like))
        }
    }

    public struct Result {
        public var result: EntryFile
        public var index: Index
    }
    
    public var results: [EntryFile] = []
    public var index = Index()

    public func list() -> [Result] {
        results.map({ entryFile in
            Result(
                result: entryFile,
                index: index.pluck(entryFile.entry.content.wikilinks())
            )
        })
    }
}
