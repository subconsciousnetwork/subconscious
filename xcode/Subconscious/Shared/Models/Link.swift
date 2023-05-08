//
//  Link.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/3/23.
//

import Foundation

/// An absolute link that can be used as an identifier, as well as a locator.
///
/// This type is used in cases where we need a stable identifier for sphere
/// content (such as in the database). A `Slashlink` can be resolved to a
/// `Link` using methods in the `Sphere` actor.
///
/// Default to using `Slashlink`, not `Link`. It is preferred to use
/// `Slashlink` for all cases where you require a *locator*. Slashlink contains
/// more useful user-facing information, such as the chain of petnames that
/// got you there.
///
/// > If we ever show a DID to a user we have failed. https://spritely.institute/static/papers/petnames.html
///
///  Use `Link` only when requiring a stable *identifier*, such as when
///  indexing database content.
struct Link: Hashable, Identifiable, LosslessStringConvertible {
    /// Regular expression for parsing links.
    /// Links have similar structure to did slashlink, but did part and slug part are both non-optional.
    private static let linkRegex = /(?<did>did:[a-z0-9]+:[a-zA-Z0-9_\-\.\%]+)(?<slug>\/[\w\-]+(?:\/[\w\-]+)*)/

    let did: Did
    let slug: Slug
    
    init(did: Did, slug: Slug) {
        self.did = did
        self.slug = slug
    }
    
    init?(_ description: String) {
        guard let match = try? Self.linkRegex.wholeMatch(
            in: description
        ) else {
            return nil
        }
        guard let did = Did(match.did.description) else {
            return nil
        }
        guard let slug = Slug(match.slug.dropFirst().description) else {
            return nil
        }
        self.init(did: did, slug: slug)
    }

    var description: String {
        "\(did.description)\(slug.markup)"
    }
    
    var id: String {
        description
    }
}

extension Link {
    init?(_ slashlink: Slashlink) {
        guard case let .did(did) = slashlink.peer else {
            return nil
        }
        self.init(did: did, slug: slashlink.slug)
    }
    
    func toSlashlink() -> Slashlink? {
        Slashlink(
            peer: Peer.did(did),
            slug: slug
        )
    }
}

extension Slashlink {
    func toLink() -> Link? {
        Link(self)
    }
}

extension Slug {
    func toLink(did: Did) -> Link {
        Link(did: did, slug: self)
    }
}

extension String {
    func toLink() -> Link? {
        Link(self)
    }
}
