//
//  MemoDataStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

struct MemoDataStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = MemoData

    private let store: FileStore
    
    init(store: FileStore) {
        self.store = store
    }

    /// Read memo from slug key
    func read(_ key: Slug) throws -> MemoData {
        try store.read(
            with: MemoData.from,
            key: String(describing: key)
                .appendingPathExtension(ContentType.memo.ext)
        )
    }

    /// Write Memo to slug key
    func write(_ key: Slug, value: MemoData) throws {
        try store.write(
            with: Data.from,
            key: String(describing: key)
                .appendingPathExtension(ContentType.memo.ext),
            value: value
        )
    }
    
    func remove(_ key: Slug) throws {
        try store.remove(
            String(describing: key)
                .appendingPathExtension(ContentType.memo.ext)
        )
    }
    
    func save() throws {}
}
