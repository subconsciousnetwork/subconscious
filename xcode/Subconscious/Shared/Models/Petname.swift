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
    private static let petnameRegex = /([\w\d\-]+)(\.[\w\d\-]+)*/
    private static let numberedSuffixRegex = /^(?<petname>(.*?))(?<separator>-+)?(?<suffix>(\d+))?$/
    
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
    
    /// Join a list of petnames into a dotted string, i.e. [foo, bar, baz] -> foo.bar.baz
    /// Names are joined in order of their appearance in `petnames`
    public init?(petnames: [Petname]) {
        let petnamePath = petnames.map({ s in s.verbatim }).joined(separator: ".")
        self.init(petnamePath)
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        self.init(Self.format(string))
    }
    
    /// Return a new petname with a numerical suffix.
    /// A plain petname e.g. `ziggy` becomes `ziggy-1`
    /// But `ziggy-1` becomes `ziggy-2` etc.
    public func increment() -> Petname? {
        guard let match = description.wholeMatch(of: Self.numberedSuffixRegex),
              let separator = match.output.separator else {
            return Petname(formatting: verbatim + "-1")
        }
        
        if let numberString = match.output.suffix,
           let number = Int(numberString) {
            return Petname(formatting: "\(match.output.petname)\(separator)\(String(number + 1))")
        } else {
            return Petname(formatting: "\(match.output.petname)\(separator)1")
        }
    }
    
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.concat(Petname("bar")` => `bar.foo`
    public func concat(petname: Petname) -> TraversalPath {
        return Petname(petnames: [petname, self])
    }
}
