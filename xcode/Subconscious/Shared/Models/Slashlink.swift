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
    private static let slashlinkRegex = /(?:(?<did>did:[a-z0-9]+:[a-zA-Z0-9_\-\.\%]+)|(?<petname>@[\w\-]+(?:\.[\w\-]+)*))?(?<slug>\/[\w\-]+(?:\/[\w\-]+)*)?/
    
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
            return slug.markup
        }
        return "\(peer.markup)\(slug.markup)"
    }

    public var verbatim: String {
        guard let peer = peer else {
            return "\(slug.verbatimMarkup)"
        }
        return "\(peer.verbatimMarkup)\(slug.verbatimMarkup)"
    }

    public var id: String { description }
    
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
        
        let slug = match.slug.map({ substring in
            // Drop leading `/`
            let slug = substring.dropFirst()
            return Slug(uncheckedRawString: slug.description)
        })
        let petname = match.petname.map({ substring in
            // Drop leading `@`
            let petname = substring.dropFirst()
            return Petname(uncheckedRawString: petname.description)
        })
        let did = match.did.map({ substring in
            Did(uncheckedRawString: substring.description)
        })
        
        // There are several valid cases:
        //
        // - did + slug
        // - did
        // - petname + slug
        // - petname
        // - slug
        //
        // All are valid constructions except for empty.
        //
        // Petname-only will use `Slug.profile` as the slug when no slug is
        // provided.
        switch (did, petname, slug) {
        case let (.some(did), .none, .some(slug)):
            self.init(peer: .did(did), slug: slug)
        case let (.some(did), .none, .none):
            self.init(peer: .did(did), slug: Slug.profile)
        case let (.none, .some(petname), .some(slug)):
            self.init(peer: .petname(petname), slug: slug)
        case let (.none, .some(petname), .none):
            self.init(peer: .petname(petname), slug: Slug.profile)
        case (.none, .none, .some(let slug)):
            self.init(slug: slug)
        default:
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
    /// - An absolute slashlink is a slashlink with a did peer or no peer
    /// - A relative slashlink is a slashlink with a petname peer.
    var isAbsolute: Bool {
        switch peer {
        case .did:
            return true
        default:
            return false
        }
    }
    
    static let ourProfile = Slashlink(slug: Slug.profile)

    var isProfile: Bool {
        slug.isProfile
    }
    
    var isOurProfile: Bool {
        self == Self.ourProfile
    }

    /// Get the petname associated with this slashlink (if any).
    /// Note that this will return nil if the slashlink has a did peer.
    /// - Returns the petname associated with the slashlink, if any.
    var petname: Petname? {
        switch self.peer {
        case .petname(let petname):
            return petname
        case .did:
            return nil
        case .none:
            return nil
        }
    }

    func toSlug() -> Slug {
        self.slug
    }
    
    /// Given a relative petname, re-base the petname relative to
    /// another petname.
    ///
    /// If this slashlink is absolute (a did slashlink) the function returns
    /// the slashlink unchanged.
    func rebaseIfNeeded(petname: Petname) -> Slashlink {
        switch self.peer {
        case .did:
            return self
        case .petname(let localPetname):
            let path = petname.join(petname: localPetname)
            return Slashlink(petname: path, slug: self.slug)
        case .none:
            return Slashlink(petname: petname, slug: self.slug)
        }
    }
    
    /// "Relativize" a slashlink relative to some base did.
    /// If did is the base did, returns a relative slashlink without a peer.
    /// Otherwise, returns slashlink unchanged.
    ///
    /// As a convenience, `did` may be nil. This is for cases where user does
    /// not have a sphere. If `did` is nil, no relativization will occur.
    ///
    /// - Parameters:
    ///   - did: the base to relativize to. May be nil for "no sphere".
    /// - Returns Slashlink
    func relativizeIfNeeded(did base: Did?) -> Slashlink {
        switch self.peer {
        case .did(let did) where did == base:
            return Slashlink(slug: self.slug)
        default:
            return self
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

extension Petname.Name {
    /// An optimized constructor that is only called internally by
    /// Slashlink.
    fileprivate init(uncheckedRawString string: String) {
        self.description = string.lowercased()
        self.verbatim = string
    }
}

extension Petname {
    /// An optimized constructor that is only called internally by
    /// Slashlink.
    fileprivate init(uncheckedRawString string: String) {
        self.init(name: Petname.Name(uncheckedRawString: string))
    }
}

extension Did {
    /// An optimized constructor that is only called by
    /// `Slashlink.init`
    fileprivate init(uncheckedRawString string: String) {
        self.did = string
    }
}

extension String {
    /// Convert a string to a slashlink
    /// - Returns Slashlink for valid slashlink string, or nil
    func toSlashlink() -> Slashlink? {
        Slashlink(self)
    }
}

extension Subtext.Slashlink {
    func toSlashlink() -> Slashlink? {
        Slashlink(description)
    }
}
