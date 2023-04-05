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
    private static let slashlinkRegex = /(\@(?<petname>[\w\d\-]+))?\/(?<slug>(?:[\w\d\-]+)(?:\/[\w\d\-]+)*)/
    
    public static func < (lhs: Slashlink, rhs: Slashlink) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public let description: String
    public let verbatim: String
    let petnamePart: String?
    let slugPart: String
    
    public var id: String { description }
    
    static let profileSlug = Slug("_profile_")!
    
    // The normalized markup form of the slashlink
    public var markup: String { description }

    public init(
        petname: Petname? = nil,
        slug: Slug
    ) {
        self.petnamePart = petname?.verbatim
        self.slugPart = slug.verbatim
        let description = "\(petname?.markup ?? "")\(slug.markup)"
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    public init?(_ description: String) {
        guard
            let match = description.wholeMatch(of: Self.slashlinkRegex)
        else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
        let slug = match.slug.toString()
        self.slugPart = slug
        self.petnamePart = match.petname?.toString()
    }
    
    /// Convenience initializer that creates a link to `@user/_profile_`
    init (petname: Petname) {
        self.init(petname: petname, slug: Self.profileSlug)
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
        self == Slashlink.profileSlug
    }
}

extension Slashlink {
    func toSlug() -> Slug {
        Slug(uncheckedRawString: self.slugPart)
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
        guard let petnamePart = self.petnamePart else {
            return nil
        }
        return Petname(uncheckedRawString: petnamePart)
    }
}

extension Subtext.Slashlink {
    func toSlashlink() -> Slashlink? {
        Slashlink(description)
    }
}
