//
//  Slashlink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/13/23.
//

import Foundation

struct Slashlink:
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
    
    init?(_ description: String) {
        guard let formatted = Self.format(description) else {
            return nil
        }
        guard formatted == description else {
            return nil
        }
        self.description = formatted
    }

    init?(formatting string: String) {
        guard let formatted = Self.format(string) else {
            return nil
        }
        self.description = formatted
    }

    /// Compare slugs by alpha
    static func < (lhs: Slashlink, rhs: Slashlink) -> Bool {
        lhs.id < rhs.id
    }

    /// Format a string to a slashlink-compatible string
    static func format(_ string: String) -> String? {
        // String must start with @ or /
        guard string.starts(with: "@") || string.starts(with: "/") else {
            return nil
        }
        return string
            .replacingOccurrences(
                of: #"[^\w\d\s\-\/\@]"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            .replacingOccurrences(
                of: #"\s"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            .replacingOccurrences(
                of: #"/+"#,
                with: "/",
                options: .regularExpression,
                range: nil
            )
            .replacingOccurrences(
                of: #"[\/\s]$"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
            .replacingOccurrences(
                of: #"\s"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
            .lowercased()
    }
}
