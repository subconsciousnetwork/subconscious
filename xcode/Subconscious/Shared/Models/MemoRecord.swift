//
//  MemoRecord.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/15/23.
//

import Foundation

/// An immutable type representing the `memo` table in our database.
/// We do some lightweight validation of invariants in the constructor.
struct MemoRecord: Hashable, Codable, Identifiable {
    let id: String
    let slashlink: Slashlink
    let did: Did
    let petname: Petname?
    let slug: Slug
    let contentType: String
    let created: Date
    let modified: Date
    let title: String
    let fileExtension: String
    let headers: Headers
    let body: String
    let description: String
    let excerpt: String
    let links: Set<Slug>
    let size: Int
    
    init(
        did: Did,
        petname: Petname?,
        slug: Slug,
        contentType: String,
        created: Date,
        modified: Date,
        title: String,
        fileExtension: String,
        headers: Headers,
        body: String,
        description: String,
        excerpt: String,
        links: Set<Slug>,
        size: Int? = nil
    ) throws {
        let link = Link(did: did, slug: slug)
        self.id = link.id

        let slashlink = Slashlink(petname: petname, slug: slug)
        self.slashlink = slashlink

        if did.isLocal && size == nil {
            throw ValueError("Record did is local, but no size provided")
        }

        if did.isLocal && petname != nil {
            throw ValueError("Record did is local, but petname is given")
        }

        self.did = did
        self.petname = petname
        self.slug = slug
        self.contentType = contentType
        self.created = created
        self.modified = modified
        self.title = title
        self.fileExtension = fileExtension
        self.headers = headers
        self.body = body
        self.description = description
        self.excerpt = excerpt
        self.links = links
        self.size = size ?? 0
    }
}
