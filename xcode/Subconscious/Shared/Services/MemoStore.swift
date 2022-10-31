//
//  MemoStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

enum EntryStoreError: Error {
    case contentTypeError(String)
}

/// MemoStore is a higher-level store that allows us to read and write
/// memos (with deserialized bodyparts) by reading both the MemoData AND
/// the file that the MemoData sidecar points to.
struct MemoStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = SubtextMemo
    
    private var files: FileStore
    private var memos: MemoDataStore
    
    init(files: FileStore) {
        self.files = files
        self.memos = MemoDataStore(store: files)
    }
    
    /// Read a SubtextEntry from slug
    func read(_ slug: Slug) throws -> SubtextMemo {
        let memo = try memos.read(slug)
        guard let contentType = memo.headers.contentType() else {
            throw EntryStoreError.contentTypeError("Missing content type")
        }
        guard contentType == ContentType.subtext else {
            throw EntryStoreError.contentTypeError(
                "Unsupported content type: \(contentType)"
            )
        }
        let info = self.info(slug)
        // We defer to file system for created and modified dates.
        // These will get peristed as headers in the database for the purpose
        // of queries, but when we read from file system, we want source of
        // truth, so we use file system instead.
        let created = info?.created ?? Date.now
        let modified = info?.modified ?? Date.now
        let title = memo.headers.title().mapOr(
            { title in title.isEmpty ? slug.toTitle() : title },
            default: slug.toTitle()
        )
        /// Read bodypart using lower-level
        let body = try files.read(
            with: Subtext.from,
            key: memo.body
        )
        return SubtextMemo(
            contentType: contentType,
            created: created,
            modified: modified,
            title: title,
            body: body
        )
    }

    /// Get just the headers for a given memo
    func headers(_ slug: Slug) throws -> Headers {
        let memo = try memos.read(slug)
        return memo.headers
    }

    /// Write a SubtextMemo to a location
    func write(_ slug: Slug, value memo: SubtextMemo) throws {
        let bodyPath = slug.toPath(memo.contentType.ext)
        let memoData = MemoData(
            headers: memo.headers,
            body: bodyPath
        )
        try memos.write(slug, value: memoData)
        try files.write(
            with: Data.from,
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
