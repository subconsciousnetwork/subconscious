//
//  Slashlink.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/13/23.
//

import Foundation

/// Represents a fully-qualified slashlink with petname and slug.
struct Slashlink:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let slashlinkRegex = /(\@(?<petname>[\w\d\-]+))?\/(?<slug>(?:[\w\d\-]+)(?:\/[\w\d\-]+)*)/
    
    static func < (lhs: Slashlink, rhs: Slashlink) -> Bool {
        lhs.id < rhs.id
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    let description: String
    let verbatim: String
    let petnamePart: String?
    let slugPart: String
    
    var id: String { description }
    
    // The normalized markup form of the slashlink
    var markup: String { description }

    init(
        petname: Petname? = nil,
        slug: Slug
    ) {
        self.petnamePart = petname?.description
        self.slugPart = slug.description
        let description = "\(petname?.markup ?? "")\(slug.markup)"
        self.description = description.lowercased()
        self.verbatim = description
    }
    
    init?(_ description: String) {
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
