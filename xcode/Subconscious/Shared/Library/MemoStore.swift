//
//  MemoStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

enum EntryStoreError: Error {
    case contentTypeMissing
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
            throw EntryStoreError.contentTypeMissing
        }
        guard contentType == ContentType.subtext.rawValue else {
            throw EntryStoreError.contentTypeError(
                "Unsupported content type: \(contentType)"
            )
        }
        /// Read bodypart using lower-level
        let body = try files.read(
            with: Subtext.from,
            key: memo.body
        )
        return SubtextMemo(headers: memo.headers, body: body)
    }

    /// Write a SubtextMemo to a location
    func write(_ slug: Slug, value memo: SubtextMemo) throws {
        guard let contentType = memo.headers.contentType() else {
            throw EntryStoreError.contentTypeMissing
        }
        guard contentType == ContentType.subtext.rawValue else {
            throw EntryStoreError.contentTypeError(
                "Unsupported content type: \(contentType)"
            )
        }
        let bodyPath = slug.toPath(ContentType.subtext.ext)
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
    func info(_ slug: Slug) throws -> FileInfo? {
        // Get memo
        let memo = try memos.read(slug)
        // Read file info from body property
        return files.info(memo.body)
    }
}

extension MemoStore {
    init(_ documentURL: URL) {
        self.init(files: FileStore(documentURL: documentURL))
    }
}
