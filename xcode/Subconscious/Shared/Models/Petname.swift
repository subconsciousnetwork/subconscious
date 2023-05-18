//
//  Petname.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/27/23.
//

import Foundation

public struct PetnamePart:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible {
    
    static let petnamePartRegex = /([\w\d\-]+)/
    private static let numberedSuffixRegex = /^(?<petname>(.*?))(?<separator>-+)?(?<suffix>(\d+))?$/
    public static let unknown = PetnamePart("unknown")!
    
    public var description: String
    public var verbatim: String
    public var id: String { description }
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }
    
    public static func < (lhs: PetnamePart, rhs: PetnamePart) -> Bool {
        lhs.description < rhs.description
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
    
    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.petnamePartRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    public init?(_ description: Substring) {
        self.init(description.toString())
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        self.init(Self.format(string))
    }
    
    public init?(formatting string: Substring) {
        self.init(Self.format(string.toString()))
    }
    
    public func toPetname() -> Petname {
        Petname(petname: self)
    }
    
    /// Return a new petname with a numerical suffix.
    /// A plain petname e.g. `ziggy` becomes `ziggy-1`
    /// But `ziggy-1` becomes `ziggy-2` etc.
    public func increment() -> PetnamePart? {
        guard let match = description.wholeMatch(of: Self.numberedSuffixRegex),
              let separator = match.output.separator else {
            return PetnamePart(formatting: verbatim + "-1")
        }
        
        if let numberString = match.output.suffix,
           let number = Int(numberString) {
            return PetnamePart(formatting: "\(match.output.petname)\(separator)\(String(number + 1))")
        } else {
            return PetnamePart(formatting: "\(match.output.petname)\(separator)1")
        }
    }
   
}

/// A type representing a valid petname (`@petname`)
public struct Petname:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible {
    
    private static let petnameRegex = /([\w\d\-]+)(\.[\w\d\-]+)*/
    public static let separator = "."
    
    public static let unknown = Petname("unknown")!
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public var description: String {
        verbatim.lowercased()
    }
    public var verbatim: String {
        self.parts.map { p in
            p.verbatim
        }.joined(separator: Self.separator)
    }
    
    public var id: String { description }
    public let parts: [PetnamePart]
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }
    
    public var isFirstOrder: Bool {
        self.parts.count == 1
    }
    
    public var leaf: PetnamePart {
        self.parts.first ?? PetnamePart.unknown
    }
    
    public var root: PetnamePart {
        self.parts.last ?? PetnamePart.unknown
    }
    
    public init?(_ description: String) {
        let parts = description.split(separator: Self.separator)
        var xs: [PetnamePart] = []
        
        for part in parts {
            guard let p = PetnamePart(part) else {
                return nil
            }
            
            xs.append(p)
        }
        
        self.parts = xs
    }
    
    /// Join a list of petnames into a dotted string, i.e. [foo, bar, baz] -> foo.bar.baz
    /// Names are joined in order of their appearance in `petnames`
    public init?(petnames: [PetnamePart]) {
        guard !petnames.isEmpty else {
            return nil
        }
        
        self.parts = petnames
    }
        
    public init(petname: PetnamePart) {
        self.parts = [petname]
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        let parts = string.split(separator: Self.separator)
        var xs: [PetnamePart] = []
        
        for part in parts {
            guard let p = PetnamePart(formatting: part) else {
                return nil
            }
            
            xs.append(p)
        }
        
        self.parts = xs
    }
     
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: PetnamePart("bar")!)` -> `bar.foo`
    public func append(petname: PetnamePart) -> Petname {
        var parts = self.parts
        parts.insert(petname, at: 0)
        return Petname(petnames: parts) ?? Petname.unknown
    }
    
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: Petname("bar")!)` -> `bar.foo`
    public func append(petname: Petname) -> Petname {
        var parts = self.parts
        parts.insert(contentsOf: petname.parts, at: 0)
        return Petname(petnames: parts) ?? Petname.unknown
    }
}
