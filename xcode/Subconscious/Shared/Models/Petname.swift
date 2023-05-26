//
//  Petname.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/27/23.
//

/// A type representing a valid petname (`@petname`)
public struct Petname:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible {
    
    public static let separator = "."
    
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
        self.parts
            .map { p in p.verbatim }
            .joined(separator: Self.separator)
    }
    
    public var id: String { description }
    public let parts: [Petname.Name]
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }
    
    public var isFirstOrder: Bool {
        self.parts.count == 1
    }
    
    public var leaf: Petname.Name {
        // Invariant: parts.count > 0
        self.parts.first!
    }
    
    public var root: Petname.Name {
        // Invariant: parts.count > 0
        self.parts.last!
    }
    
    public init(part: Petname.Name) {
        self.parts = [part]
    }
    
    /// Join a list of petnames into a dotted string, i.e. [foo, bar, baz] -> foo.bar.baz
    /// Names are joined in order of their appearance in `petnames`
    public init?(parts: [Petname.Name]) {
        guard !parts.isEmpty else {
            return nil
        }
        
        guard !parts.contains(where: { part in part.verbatim.isEmpty }) else {
            return nil
        }
        
        self.parts = parts
    }
    
    public init?(_ description: String) {
        let parts = description.components(separatedBy: Self.separator)
        let mappedParts = parts.compactMap { part in Petname.Name(part) }
        guard parts.count == mappedParts.count else {
            return nil
        }
        
        self.init(parts: mappedParts)
    }
    
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        let parts = string.split(separator: Self.separator)
        let mappedParts = parts.compactMap { part in Petname.Name(formatting: part) }
        guard parts.count == mappedParts.count else {
            return nil
        }
        
        self.init(parts: mappedParts)
    }
     
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: Petname.Part("bar")!)` -> `bar.foo`
    public func append(name: Petname.Name) -> Petname? {
        var parts = self.parts
        parts.insert(name, at: 0)
        return Petname(parts: parts)
    }
    
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: Petname("bar")!)` -> `bar.foo`
    public func append(petname: Petname) -> Petname? {
        var parts = self.parts
        parts.insert(contentsOf: petname.parts, at: 0)
        return Petname(parts: parts)
    }
}

// MARK: Petname.Name
extension Petname {
    public struct Name:
        Hashable,
        Equatable,
        Identifiable,
        Comparable,
        Codable,
        LosslessStringConvertible {
        
        static let partRegex = /([\w\d\-]+)/
        private static let numberedSuffixRegex = /^(?<petname>(.*?))(?<separator>-+)?(?<suffix>(\d+))?$/
        public static let unknown = Petname.Name("unknown")!
        
        public var description: String
        public var verbatim: String
        public var id: String { description }
        
        public var markup: String {
            "@\(self.description)"
        }
        
        public var verbatimMarkup: String {
            "@\(self.verbatim)"
        }
        
        public static func < (lhs: Petname.Name, rhs: Petname.Name) -> Bool {
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
            guard description.wholeMatch(of: Self.partRegex) != nil else {
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
            Petname(part: self)
        }
        
        /// Return a new petname with a numerical suffix.
        /// A plain petname e.g. `ziggy` becomes `ziggy-1`
        /// But `ziggy-1` becomes `ziggy-2` etc.
        public func increment() -> Petname.Name? {
            guard let match = description.wholeMatch(of: Self.numberedSuffixRegex),
                  let separator = match.output.separator else {
                return Petname.Name(formatting: verbatim + "-1")
            }
            
            if let numberString = match.output.suffix,
               let number = Int(numberString) {
                return Petname.Name(formatting: "\(match.output.petname)\(separator)\(String(number + 1))")
            } else {
                return Petname.Name(formatting: "\(match.output.petname)\(separator)1")
            }
        }
       
    }
}
