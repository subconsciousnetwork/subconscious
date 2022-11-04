//
//  HeaderSubtextStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/4/22.
//

import Foundation

/// Reads and writes header-flavored Subtext files.
struct HeaderSubtextMemoStore {
    private var store: StoreProtocol
    
    init(store: StoreProtocol) {
        self.store = store
    }
    
    /// Read memo from slug key
    func read(_ slug: Slug) throws -> Memo {
        let path = slug.toPath(ContentType.subtext.fileExtension)
        let fallbackHeaders = WellKnownHeaders(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: slug.toTitle(),
            fileExtension: ContentType.subtext.rawValue
        )
        return try store.read(
            with: { data in
                data.toString()?
                    .toHeadersEnvelope()
                    .toMemo(fallback: fallbackHeaders)
            },
            key: path
        )
    }
    
    /// Write Memo to slug key
    func write(_ slug: Slug, value: Memo) throws {
        try store.write(
            with: { memo in
                memo.toHeadersEnvelope()
                    .description
                    .toData()
            },
            key: slug.toPath(ContentType.subtext.fileExtension),
            value: value
        )
    }
    
    func remove(_ slug: Slug) throws {
        try store.remove(slug.toPath(ContentType.subtext.fileExtension))
    }
    
    func save() throws {}
    
    /// List all memo slugs
    func list() throws -> [Slug] {
        try store.list()
            .compactMap({ path in
                let ext = ContentType.subtext.fileExtension
                guard path.hasExtension(ext) else {
                    return nil
                }
                guard let path = path.deletingPathExtension(ext) else {
                    return nil
                }
                return Slug(path)
            })
    }

    func info(_ key: Slug) throws -> FileInfo {
        try store.info(key.toPath(ContentType.subtext.fileExtension))
    }
}
