//
//  Petname.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/27/23.
//

import Foundation

/// A type representing a valid petname (`@petname`)
public struct Petname:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let petnameRegex = /[\w\d\-]+/
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
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

    public let description: String
    public let verbatim: String
    public var id: String { description }
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }

    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.petnameRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        self.init(Self.format(string))
    }
}

