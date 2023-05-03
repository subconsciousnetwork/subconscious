//
//  Did+SubconsciousLocalFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/1/23.
//
//  Extends Did to include a the non-standard `did:subconscious:local`.
//  We keep the extension here so that Did is not complected with this
//  app-specific nonstandard concept.

import SwiftUI

extension Did {
    /// A non-standard did we use to represent the local file system.
    static let local = Did("did:subconscious:local")!
}

extension Slashlink {
    // Create a slashlink that points to content on the local file system
    static func local(_ slug: Slug) -> Self {
        Slashlink(peer: Peer.did(Did.local), slug: slug)
    }

    /// Does this slashlink point to content saved to the local file system,
    /// rather than a sphere?
    var isLocal: Bool {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return true
        default:
            return false
        }
    }
    
    /// Check if slashlink points to content that belongs to us.
    var isOurs: Bool {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return true
        case .did:
            return false
        case .petname:
            return false
        case .none:
            return true
        }
    }
    
    /// Get audience from slashlink
    func toAudience() -> Audience {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return .local
        case .did:
            return .public
        case .petname:
            return .public
        case .none:
            return .public
        }
    }
    
    /// Rebase slashlink using audience.
    ///
    /// Note that this method will toss the current peer, so if it points
    /// to a 3p, it will now be a pointer to our content.
    func withAudience(_ audience: Audience) -> Slashlink {
        switch audience {
        case .local:
            return Slashlink(
                peer: Peer.did(Did.local),
                slug: self.slug
            )
        case .public:
            return Slashlink(slug: slug)
        }
    }
}

extension Slug {
    /// Get slashlink based on local content storage did
    func toLocalSlashlink() -> Slashlink {
        Slashlink(
            peer: .did(Did.local),
            slug: self
        )
    }
    
    /// Transform slug into slashlink with audience
    func toSlashlink(audience: Audience) -> Slashlink {
        switch audience {
        case .local:
            return Slashlink(
                peer: .did(Did.local),
                slug: self
            )
        case .public:
            return Slashlink(slug: self)
        }
    }
    
    /// Create an absolute `Link` from a slug to a local file.
    func toLocalLink() -> Link? {
        Link(did: Did.local, slug: self)
    }
}

extension Link {
    /// Is link to a local file?
    var isLocal: Bool {
        did == Did.local
    }
}

extension Image {
    init(_ address: Slashlink) {
        guard !address.isLocal else {
            self.init(systemName: "circle.dashed")
            return
        }
        self.init(systemName: "network")
    }
}
