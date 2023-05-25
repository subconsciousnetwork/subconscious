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
    
    private static let petnameRegex = /([\w\d\-]+)(\.[\w\d\-]+)*/
    public static let separator = "."
    
    public static let unknown = Petname(part: Part.unknown)
    
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
    public let parts: [Petname.Part]
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }
    
    public var isFirstOrder: Bool {
        self.parts.count == 1
    }
    
    public var leaf: Petname.Part {
        self.parts.first ?? Petname.Part.unknown
    }
    
    public var root: Petname.Part {
        self.parts.last ?? Petname.Part.unknown
    }
    
    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.petnameRegex) != nil else {
            return nil
        }
        let parts = description.split(separator: Self.separator)
        self.parts = parts.compactMap { part in Petname.Part(part) }
    }
    
    /// Join a list of petnames into a dotted string, i.e. [foo, bar, baz] -> foo.bar.baz
    /// Names are joined in order of their appearance in `petnames`
    public init?(parts: [Petname.Part]) {
        guard !parts.isEmpty else {
            return nil
        }
        
        self.parts = parts
    }
        
    public init(part: Petname.Part) {
        self.parts = [part]
    }
    
    /// Convert a string into a petname.
    /// This will sanitize the string as best it can to create a valid petname.
    public init?(formatting string: String) {
        let parts = string.split(separator: Self.separator)
        var xs: [Petname.Part] = []
        
        for part in parts {
            guard let p = Petname.Part(formatting: part) else {
                return nil
            }
            
            xs.append(p)
        }
        
        self.parts = xs
    }
     
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: Petname.Part("bar")!)` -> `bar.foo`
    public func append(petname: Petname.Part) -> Petname {
        var parts = self.parts
        parts.insert(petname, at: 0)
        return Petname(parts: parts) ?? Petname.unknown
    }
    
    /// Combines two petnames to build up a traversal path
    /// i.e. `Petname("foo")!.append(petname: Petname("bar")!)` -> `bar.foo`
    public func append(petname: Petname) -> Petname {
        var parts = self.parts
        parts.insert(contentsOf: petname.parts, at: 0)
        return Petname(parts: parts) ?? Petname.unknown
    }
}

// MARK: Petname.Part
extension Petname {
    public struct Part:
        Hashable,
        Equatable,
        Identifiable,
        Comparable,
        Codable,
        LosslessStringConvertible {
        
        static let partRegex = /([\w\d\-]+)/
        private static let numberedSuffixRegex = /^(?<petname>(.*?))(?<separator>-+)?(?<suffix>(\d+))?$/
        public static let unknown = Petname.Part("unknown")!
        
        public var description: String
        public var verbatim: String
        public var id: String { description }
        
        public var markup: String {
            "@\(self.description)"
        }
        
        public var verbatimMarkup: String {
            "@\(self.verbatim)"
        }
        
        public static func < (lhs: Petname.Part, rhs: Petname.Part) -> Bool {
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
        public func increment() -> Petname.Part? {
            guard let match = description.wholeMatch(of: Self.numberedSuffixRegex),
                  let separator = match.output.separator else {
                return Petname.Part(formatting: verbatim + "-1")
            }
            
            if let numberString = match.output.suffix,
               let number = Int(numberString) {
                return Petname.Part(formatting: "\(match.output.petname)\(separator)\(String(number + 1))")
            } else {
                return Petname.Part(formatting: "\(match.output.petname)\(separator)1")
            }
        }
       
    }
}
