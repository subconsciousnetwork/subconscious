//
//  Petname.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/27/23.
//

import Foundation

/// A type representing a valid petname (`@petname`)
struct Petname:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let petnameRegex = /[\w\d\-]+/
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.id < rhs.id
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    /// Attempt to sanitize a string into a "petname string" - a string that
    /// can can be losslessly converted to a petname.
    private static func format(_ string: String) -> String {
        // Strip all non-allowed characters
        let formatted = string.replacingOccurrences(
            of: #"[^\w\d\-\s]"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
        // Trim leading/trailing whitespace
        .trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace runs of one or more space with a single dash
        .replacingOccurrences(
            of: #"\s+"#,
            with: "-",
            options: .regularExpression,
            range: nil
        )
        return formatted
    }

    let description: String
    let verbatim: String
    var id: String { description }
    
    var markup: String {
        "@\(self.verbatim)"
    }
    
    init?(_ description: String) {
        guard description.wholeMatch(of: Self.petnameRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    init?(formatting string: String) {
        self.init(Self.format(string))
    }
}

