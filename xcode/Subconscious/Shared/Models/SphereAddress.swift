//
//  SphereAddress.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/1/23.
//

import Foundation

/// An Absolute Slashlink is an unambiguous identifier for a piece of content
/// that belongs to a sphere.
///
/// We only use this type internally, to use type safety to ensure that
/// database writes, which require an absolute unchanging identifier, are
/// given the correct type of value.
struct SphereAddress: Hashable, LosslessStringConvertible, Identifiable {
    init(
        did: Did,
        slug: Slug
    ) {
        self.did = did
        self.slug = slug
    }

    init?(_ slashlink: Slashlink) {
        guard case let .did(did) = slashlink.peer else {
            return nil
        }
        self.init(did: did, slug: slashlink.slug)
    }

    init?(_ description: String) {
        guard let slashlink = Slashlink(description) else {
            return nil
        }
        self.init(slashlink)
    }
    
    private let did: Did
    private let slug: Slug
    
    var description: String {
        "\(did)\(slug.markup)"
    }
    
    var id: String {
        description
    }
}
