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
    
    let peer: Peer?
    let slug: Slug
    
    public var description: String {
        guard let peer = peer else {
            return "/\(slug.description)"
        }
        return "@\(peer.description)/\(slug.description)"
    }

    public var verbatim: String {
        guard let peer = peer else {
            return "/\(slug.verbatim)"
        }
        return "@\(peer.verbatim)/\(slug.verbatim)"
    }

    public var id: String { description }
    
    static let ourProfile = Slashlink(slug: Slug.profile)
    
    // The normalized markup form of the slashlink
    public var markup: String { description }

    // The non-normalized markup form of the slashlink
    public var verbatimMarkup: String { verbatim }

    public init(
        peer: Peer? = nil,
        slug: Slug
    ) {
        self.peer = peer
        self.slug = slug
    }
    
    public init?(_ description: String) {
        guard
            let match = description.wholeMatch(of: Self.slashlinkRegex)
        else {
            return nil
        }
        
        // There are four cases: peer-only, slug-only, peer+slug and empty.
        // All are valid constructions except for empty.
        // Petname-only will use `profileSlug` as the slug.
        let slug = match.slug.map({ substring in
            Slug(uncheckedRawString: substring.toString()
        )})
        let peer = match.petname.map({ substring in
            Peer.petname(
                Petname(uncheckedRawString: substring.toString())
            )
        })
        
        switch (peer, slug) {
        case (.some(let peer), .some(let slug)):
            self.init(peer: peer, slug: slug)
        case (.none, .some(let slug)):
            self.init(slug: slug)
        case (.some(let peer), .none):
            self.init(peer: peer, slug: Slug.profile)
        case (_, _):
            return nil
        }
    }
    
    /// Convenience initializer that lets you create a relative slashlink
    /// from a petname and slug.
    init(petname: Petname?, slug: Slug) {
        self.init(
            peer: petname.map({ petname in Peer.petname(petname) }),
            slug: slug
        )
    }

    /// Convenience initializer that creates a link to `@user/_profile_`
    init(petname: Petname) {
        self.init(
            peer: Peer.petname(petname),
            slug: Slug.profile
        )
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
    /// Transform slug into slashlink
    /// - Parameters:
    ///   - peer: the peer for the sphere this slug belongs to (if any)
    /// - Returns: slashlink
    func toSlashlink(relativeTo petname: Petname? = nil) -> Slashlink {
        Slashlink(
            petname: petname,
            slug: self
        )
    }
}

extension Slashlink {
    /// Is slashlink absolute?
    /// - An absolute slashlink is a slashlink with a did peer.
    /// - A relative slashlink is a slashlink with a petname peer, or no peer.
    var isAbsolute: Bool {
        peer?.isAbsolute ?? false
    }

    func toSlug() -> Slug {
        self.slug
    }
    
    /// Given a relative petname, re-root the petname relative to
    /// another petname.
    ///
    /// If this slashlink is absolute (a did slashlink) the function returns
    /// nil.
    func relativeTo(petname: Petname) -> Slashlink? {
        switch self.peer {
        case .petname(let localPetname):
            let path = petname.append(petname: localPetname)
            return Slashlink(petname: path, slug: self.slug)
        case .none:
            return Slashlink(petname: petname, slug: self.slug)
        default:
            return nil
        }
    }
    
    /// Get petname from slashlink (if any)
    func toPetname() -> Petname? {
        switch self.peer {
        case .petname(let petname):
            return petname
        default:
            return nil
        }
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

extension Subtext.Slashlink {
    func toSlashlink() -> Slashlink? {
        Slashlink(description)
    }
}
