//
//  Slashlink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/13/23.
//

import Foundation

/// A nickname is a handle that can be used in a slashlink.
/// It's a nickname when its your preferred, it's a petname when someone
/// else gives it to you.
struct Nickname:
    Hashable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    let description: String
    
    var id: String {
        description
    }
    
    init?(_ string: String) {
        let formatted = Self.format(string)
        guard formatted == string else {
            return nil
        }
        self.description = formatted
    }

    init(formatting string: String) {
        self.description = Self.format(string)
    }

    /// Compare slugs by alpha
    static func < (lhs: Nickname, rhs: Nickname) -> Bool {
        lhs.id < rhs.id
    }

    /// Format a string to a slashlink-compatible string
    static func format(_ string: String) -> String {
        return string
            .replacingOccurrences(
                of: #"[^\w\d\s\-]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: #"\s"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            .lowercased()
    }
}
