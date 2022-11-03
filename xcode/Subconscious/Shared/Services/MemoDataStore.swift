//
//  MemoDataStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/21/22.
//

import Foundation

/// Reads and writes MemoData
/// A MemoData is a struct that contains headers and a path to a file
/// on disk containing the bodypart.
///
/// This is a lightweight datatype that is often read into `Memo<T>` type
/// using higher-level APIs.
struct MemoDataStore: StoreProtocol {
    typealias Key = Slug
    typealias Value = MemoData
    
    private let store: FileStore
    
    init(store: FileStore) {
        self.store = store
    }
    
    /// Read memo from slug key
    func read(_ slug: Slug) throws -> MemoData {
        try store.read(
            with: { data in data.toMemoData() },
            key: slug.toPath(ContentType.memo.fileExtension)
        )
    }
    
    /// Write Memo to slug key
    func write(_ slug: Slug, value: MemoData) throws {
        try store.write(
            with: { memo in memo.toData() },
            key: slug.toPath(ContentType.memo.fileExtension),
            value: value
        )
    }
    
    func remove(_ slug: Slug) throws {
        try store.remove(slug.toPath(ContentType.memo.fileExtension))
    }
    
    func save() throws {}
    
    /// List all memo slugs
    func list() throws -> some Sequence<Slug> {
        try store.list()
            .lazy
            .filter({ path in
                path.hasExtension(ContentType.memo.fileExtension)
            })
            .compactMap({ path in
                Slug(path.deletingPathExtension())
            })
    }
}
