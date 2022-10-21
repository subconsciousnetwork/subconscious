//
//  EntryStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

enum EntryStoreError: Error {
    case contentTypeMissing
    case contentTypeError(String)
}

/// EntryStore is a high-level store that allows us to read and write
/// fully reified datatypes with sidecar metadata.
struct EntryStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = SubtextEntry

    private var fs: FileStore
    private var memos: MemoDataStore

    init(fs: FileStore) {
        self.fs = fs
        self.memos = MemoDataStore(store: fs)
    }

    /// Read a SubtextEntry from slug
    func read(_ slug: Slug) throws -> SubtextEntry {
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
        let body = try fs.read(
            with: Subtext.from,
            key: memo.body
        )
        return SubtextEntry(
            slug: slug,
            contents: Memo(
                headers: memo.headers,
                body: body
            )
        )
    }
    
    func write(_ slug: Slug, value entry: SubtextEntry) throws {
        guard let contentType = entry.contents.headers.contentType() else {
            throw EntryStoreError.contentTypeMissing
        }
        guard contentType == ContentType.subtext.rawValue else {
            throw EntryStoreError.contentTypeError(
                "Unsupported content type: \(contentType)"
            )
        }
        let memoData = MemoData(entry)
        try memos.write(slug, value: memoData)
        try fs.write(
            with: Data.from,
            key: memoData.body,
            value: entry.contents.body
        )
    }
    
    func remove(_ slug: Slug) throws {
        // Get memo to get body location
        let memo = try memos.read(slug)
        // Remove memo
        try memos.remove(slug)
        // Remove body file
        try fs.remove(memo.body)
    }
    
    func save() throws {}
}
