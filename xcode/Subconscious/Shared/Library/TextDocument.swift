//
//  TextFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation

/// An in-memory representation of a text file.
struct TextDocument:
    CustomStringConvertible, Identifiable, Hashable, Equatable {
    var description: String { content }
    var id: URL { url }

    /// File URL
    let url: URL
    /// File content as string
    let content: String
}
