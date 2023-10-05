//
//  TranscludeService.swift
//  Subconscious
//
//  Created by Ben Follington on 5/5/2023.
//

import Foundation
import Combine

struct Transclusion {
    let displayAddress: Slashlink
    let address: Slashlink
    let authorDid: Did
}

actor TranscludeService {
    private var database: DatabaseService
    private var noosphere: NoosphereService
    private var userProfile: UserProfileService
    
    init(
        database: DatabaseService,
        noosphere: NoosphereService,
        userProfile: UserProfileService
    ) {
        self.database = database
        self.noosphere = noosphere
        self.userProfile = userProfile
    }
    
    func resolveAddresses(base: Peer?, link: Slashlink) async throws -> Transclusion {
        let address = base.map { base in
            link.rebaseIfNeeded(peer: base)
        }
        .unwrap(or: link)
       
        let did = try await noosphere.resolve(peer: address.peer)
        
        return Transclusion(
            displayAddress: link,
            address: address,
            authorDid: did
        )
    }
    
    func fetchTranscludePreviews(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async throws -> [Slashlink: EntryStub] {
        var dict: [Slashlink: EntryStub] = [:]
        
        for link in slashlinks {
            let transclusion = try await resolveAddresses(
                base: owner.address.peer,
                link: link
            )
            
            let address = Slashlink(peer: .did(transclusion.authorDid), slug: link.slug)
            guard var entry = try database.readEntry(for: address) else {
                continue
            }
            
            if let author = try? await userProfile.buildUserProfile(
                address: transclusion.address,
                did: transclusion.authorDid
            ) {
                entry = entry.withAuthor(author)
            }
            
            if entry.address.isLocal {
                dict.updateValue(entry, forKey: Slashlink(slug: entry.address.slug))
                continue
            }
            
            dict.updateValue(entry, forKey: transclusion.displayAddress)
        }
        
        return dict
    }

    
    nonisolated func fetchTranscludePreviewsPublisher(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) -> AnyPublisher<[Slashlink: EntryStub], Error> {
        Future.detached(priority: .utility) {
            try await self.fetchTranscludePreviews(
                slashlinks: slashlinks,
                owner: owner
            )
        }
        .eraseToAnyPublisher()
    }
}
