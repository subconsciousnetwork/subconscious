//
//  ContentType.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/15/22.
//

import Foundation

/// A struct containing information about particular content types
struct ContentType: Hashable, CustomStringConvertible {
    var contentType: String
    var ext: String

    var description: String {
        contentType
    }
}

/// Extend ContentType with constants for useful types
extension ContentType {
    static let subtext = ContentType(
        contentType: "text/subtext",
        ext: "subtext"
    )
    
    static let memo = ContentType(
        contentType: "application/json",
        ext: "memo"
    )
}
