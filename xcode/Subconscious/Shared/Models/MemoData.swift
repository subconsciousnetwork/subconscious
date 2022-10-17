//
//  MemoData.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/17/22.
//

import Foundation

/// A MemoSidecar is a Codable that represents a memo structure
/// as it would appear on-disk.
struct MemoData: Hashable, Codable {
    /// A collection of headers
    let headers: Headers
    /// A path-like string that points to the conceptual bodypart that
    /// corresponds to this sidecar file.
    let contents: String

    var contentType: String {
        headers.first(named: "Content-Type")?.value ?? ""
    }
}
