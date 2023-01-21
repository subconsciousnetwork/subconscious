//
//  MemoData.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A MemoData represents not-yet-decoded memo.
///
/// We typically convert this to `Memo<T>` in order to work with it more
/// effectively.
struct MemoData: Hashable, Codable {
    /// The value of the `Content-Type` header.
    let contentType: String
    /// A collection of headers
    let additionalHeaders: [Header]
    /// The raw bytes of the body part.
    let body: Data
}
