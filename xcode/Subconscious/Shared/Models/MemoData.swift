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
public struct MemoData: Hashable, Codable {
    /// The value of the `Content-Type` header.
    public let contentType: String
    /// A collection of headers
    public let additionalHeaders: [Header]
    /// The raw bytes of the body part.
    public let body: Data
}
