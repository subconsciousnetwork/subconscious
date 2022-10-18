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
    var headers: Headers
    var contents: T
}

typealias SubtextMemo = Memo<Subtext>

extension FileStore {
    /// Read a subtext memo from a slug
    /// This is two reads:
    /// - Once for memo
    /// - Once for Subtext file
    func read(_ key: String) throws -> SubtextMemo {
        let sidecar = try read(
            with: MemoData.from,
            key: key.appendingPathExtension(ContentType.memo.ext)
        )
        let contentType = sidecar.headers.contentType().unwrap(or: "")
        guard contentType == ContentType.subtext.contentType else {
            throw FileStoreError.contentTypeError(contentType)
        }
        let subtext = try read(
            with: Subtext.from,
            key: key.appendingPathExtension(ContentType.subtext.ext)
        )
        return Memo(headers: sidecar.headers, contents: subtext)
    }

    /// Write SubtextMemo to Memo and Subtext file on disk
    /// This is two writes:
    /// - Once for memo file
    /// - Once for Subtext file
    func write(_ key: String, memo: SubtextMemo) throws {
        let contentType = memo.headers.contentType().unwrap(or: "")
        guard contentType == ContentType.subtext.contentType else {
            throw FileStoreError.contentTypeError(contentType)
        }
        let memoKey = key.appendingPathExtension(ContentType.memo.ext)
        let subtextKey = key.appendingPathExtension(ContentType.subtext.ext)
        let memoData = MemoData(headers: memo.headers, contents: subtextKey)
        try write(with: Data.from, key: memoKey, value: memoData)
        try write(with: Data.from, key: subtextKey, value: memo.contents)
    }
}
