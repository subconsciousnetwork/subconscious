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
    let absoluteAddress: Slashlink
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
            absoluteAddress: Slashlink(peer: .did(did), slug: address.slug)
        )
    }
    
    func fetchTranscludePreviews(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async throws -> [Slashlink: AuthoredEntryStub] {
        var dict: [Slashlink: AuthoredEntryStub] = [:]
        
        for link in slashlinks {
            let transclusion = try await resolveAddresses(
                base: owner.address.peer,
                link: link
            )
            guard let entry = try database.readEntry(for: transclusion.absoluteAddress) else {
                continue
            }
            
            guard let author = try? await userProfile.loadFullProfileData(address: transclusion.address) else {
                continue
            }
            let authoredEntry = AuthoredEntryStub(author: author.profile, entry: entry)
            
            if entry.address.isLocal {
                dict.updateValue(authoredEntry, forKey: Slashlink(slug: entry.address.slug))
                continue
            }
            
            dict.updateValue(authoredEntry, forKey: transclusion.displayAddress)
        }
        
        return dict
    }

    
    nonisolated func fetchTranscludePreviewsPublisher(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) -> AnyPublisher<[Slashlink: AuthoredEntryStub], Error> {
        Future.detached(priority: .utility) {
            try await self.fetchTranscludePreviews(
                slashlinks: slashlinks,
                owner: owner
            )
        }
        .eraseToAnyPublisher()
    }
}
