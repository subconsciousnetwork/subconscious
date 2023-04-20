//
//  Slashlink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/13/23.
//

import Foundation

/// Represents a fully-qualified slashlink with petname and slug.
public struct Slashlink:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let slashlinkRegex = /(\@(?<petname>(?:[\w\d\-]+)(?:\.[\w\d\-]+)*))?(\/(?<slug>(?:[\w\d\-]+)(?:\/[\w\d\-]+)*))?/
    
    public static func < (lhs: Slashlink, rhs: Slashlink) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    let petname: Petname?
    let slug: Slug
    
    public var description: String {
        guard let petname = petname else {
            return "/\(slug.description)"
        }
        return "@\(petname.description)/\(slug.description)"
    }

    public var verbatim: String {
        guard let petname = petname else {
            return "/\(slug.verbatim)"
        }
        return "@\(petname.verbatim)/\(slug.verbatim)"
    }

    public var id: String { description }
    
    static let ourProfile = Slashlink(slug: Slug.profile)
    
    // The normalized markup form of the slashlink
    public var markup: String { description }

    // The non-normalized markup form of the slashlink
    public var verbatimMarkup: String { verbatim }

    public init(
        petname: Petname? = nil,
        slug: Slug
    ) {
        self.petname = petname
        self.slug = slug
    }
    
    public init?(_ description: String) {
        guard
            let match = description.wholeMatch(of: Self.slashlinkRegex)
        else {
            return nil
        }
        
        // There are four cases: petname-only, slug-only, petname+slug and empty.
        // All are valid constructions except for empty.
        // Petname-only will use `profileSlug` as the slug.
        let slug = match.slug.map({ substring in
            Slug(uncheckedRawString: substring.toString()
        )})
        let petname = match.petname.map({ substring in
            Petname(uncheckedRawString: substring.toString())
        })
        
        switch (petname, slug) {
        case (.some(let petname), .some(let slug)):
            self.init(petname: petname, slug: slug)
        case (.none, .some(let slug)):
            self.init(slug: slug)
        case (.some(let petname), .none):
            self.init(petname: petname, slug: Slug.profile)
        case (_, _):
            return nil
        }
    }
    
    /// Convenience initializer that creates a link to `@user/_profile_`
    init(petname: Petname) {
        self.init(petname: petname, slug: Slug.profile)
    }
}

extension Slug {
    /// An optimized constructor that is only called by
    /// `Slashlink.init`
    fileprivate init(uncheckedRawString string: String) {
        self.description = string.lowercased()
        self.verbatim = string
    }
}

extension Slug {
    func toSlashlink() -> Slashlink {
        Slashlink(slug: self)
    }
    
    func isProfile() -> Bool {
        self == Slug.profile
    }
}

extension Slashlink {
    func toSlug() -> Slug {
        self.slug
    }
    
    func relativeTo(petname: Petname) -> Slashlink {
        guard let localPetname = self.petname else {
            return Slashlink(petname: petname, slug: self.slug)
        }
        
        let path = petname.append(petname: localPetname)
        return Slashlink(petname: path, slug: self.slug)
    }
}

extension Petname {
    /// An optimized constructor that is only called internally by
    /// Slashlink.
    fileprivate init(uncheckedRawString string: String) {
        self.description = string.lowercased()
        self.verbatim = string
    }
}

extension Slashlink {
    func toPetname() -> Petname? {
        self.petname
    }
}

extension Subtext.Slashlink {
    func toSlashlink() -> Slashlink? {
        Slashlink(description)
    }
}
