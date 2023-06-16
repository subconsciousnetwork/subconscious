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
    /// The DID of the sphere this content belongs to
    let did: Did
    /// Slashlink for this content. Constructed from petname and slug, and
    /// indexed with content for type-ahead link completion.
    let slashlink: Slashlink
    /// The petname, if any, for this sphere.
    let petname: Petname?
    /// The slug of the content
    let slug: Slug
    let contentType: String
    let created: Date
    let modified: Date
    /// A title derived from the memo.
    /// Used for search.
    let title: String
    let fileExtension: String
    let headers: Headers
    /// The contents of the memo.
    let body: String
    /// A plain text serialization of the body for search indexing.
    /// For subtext, this is the same as `body`. For other content types, it
    /// might be something else.
    let description: String
    /// An excerpt of the body content.
    let excerpt: String
    let links: Set<Slug>
    /// The total file size on disk in bytes, including inlined headers for
    /// HeaderSubtext.
    ///
    /// This is only used for local files, not sphere files.
    /// We use modified time and size as a signal when indexing.
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
