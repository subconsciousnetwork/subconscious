//
//  MemoStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

/// MemoStore is a higher-level store that allows us to read and write
/// memos (with deserialized bodyparts) by reading both the MemoData AND
/// the file that the MemoData sidecar points to.
struct MemoStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = Memo
    
    private var files: FileStore
    private var memos: MemoDataStore
    
    init(files: FileStore) {
        self.files = files
        self.memos = MemoDataStore(store: files)
    }
    
    /// Read a Memo from slug
    /// This method does a bit of work to clean up missing metadata
    /// so when we write it back out, we get well-formed meta.
    func read(_ slug: Slug) throws -> Memo {
        let memoData = try memos.read(slug)

        let info = self.info(slug)

        let fallback = WellKnownHeaders(
            contentType: ContentType.text.rawValue,
            created: info?.created ?? Date.now,
            modified: info?.modified ?? Date.now,
            title: slug.toTitle(),
            fileExtension: ContentType.text.fileExtension
        )

        let headers = WellKnownHeaders(
            headers: memoData.headers,
            fallback: fallback
        )

        /// Read bodypart using lower-level file store
        let body = try files.read(
            with: { data in data.toString() },
            key: memoData.body
        )

        return Memo(
            contentType: headers.contentType,
            created: headers.created,
            modified: headers.modified,
            title: headers.title,
            fileExtension: headers.fileExtension,
            // Include the entirety of the headers. We don't worry about
            // duplicates in the well-known header properties. The well-known
            // values will win when we use the `headers` property of Memo.
            other: memoData.headers,
            body: body
        )
    }

    /// Get just the headers for a given memo
    func headers(_ slug: Slug) throws -> Headers {
        let memo = try memos.read(slug)
        return memo.headers
    }

    /// Write a SubtextMemo to a location
    func write(_ slug: Slug, value memo: Memo) throws {
        let bodyPath = slug.toPath(memo.fileExtension)
        let memoData = MemoData(
            headers: memo.headers,
            body: bodyPath
        )
        try memos.write(slug, value: memoData)
        try files.write(
            with: { string in string.toData() },
            key: bodyPath,
            value: memo.body
        )
    }
    
    func remove(_ slug: Slug) throws {
        // Get memo to get body location
        let memo = try memos.read(slug)
        // Remove memo
        try memos.remove(slug)
        // Remove body file
        try files.remove(memo.body)
    }
    
    func save() throws {}
    
    func list() throws -> some Sequence<Slug> {
        try memos.list()
    }

    // Get info for slug
    func info(_ slug: Slug) -> FileInfo? {
        // Get memo
        guard let memo = try? memos.read(slug) else {
            return nil
        }
        // Read file info from body property
        return files.info(memo.body)
    }
}

extension MemoStore {
    init(_ documentURL: URL) {
        self.init(files: FileStore(documentURL: documentURL))
    }
}
