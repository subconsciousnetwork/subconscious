//
//  MemoData.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A MemoSidecar is a Codable that represents a minimal memo structure
/// as it would appear on-disk.
///
/// We typically convert this to `Memo<T>` in order to work with it more
/// effectively.
struct MemoData: Hashable, Codable {
    /// A collection of headers
    let headers: Headers
    /// A path-like string that points to the conceptual bodypart that
    /// corresponds to this sidecar file.
    let contents: String
}
