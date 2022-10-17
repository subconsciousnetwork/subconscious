//
//  Memo.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A "reified" memo who's bodypart has been loaded and decoded
struct Memo<T>: Hashable
where T: Hashable
{
    let headers: Headers
    let contents: T

    var contentType: String {
        headers.first(named: "Content-Type")?.value ?? ""
    }
}

extension FileStore {
    /// Read a subtext memo from a slug
    func readMemo(_ key: String) throws -> Memo<Subtext> {
        let sidecar = try read(
            with: MemoData.from,
            key: key.appendingPathExtension(ContentType.memo.ext)
        )
        guard sidecar.contentType == ContentType.subtext.contentType else {
            throw FileStoreError.contentTypeError(sidecar.contentType)
        }
        let subtext = try read(
            with: Subtext.from,
            key: key.appendingPathExtension(ContentType.subtext.ext)
        )
        return Memo(headers: sidecar.headers, contents: subtext)
    }

    func writeMemo(_ slug: Slug, memo: Memo<Subtext>) throws {
        guard memo.contentType == ContentType.subtext.contentType else {
            throw FileStoreError.contentTypeError(memo.contentType)
        }
        let baseKey = String(slug)
        let memoKey = baseKey.appendingPathExtension(ContentType.memo.ext)
        let subtextKey = baseKey
            .appendingPathExtension(ContentType.subtext.ext)
        let memoData = MemoData(headers: memo.headers, contents: subtextKey)
        try write(with: Data.from, key: memoKey, value: memoData)
        try write(with: Data.from, key: subtextKey, value: memo.contents)
    }
}
