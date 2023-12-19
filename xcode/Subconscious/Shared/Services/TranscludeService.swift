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
    
    func resolveAddresses(
        base: Peer?,
        link: Slashlink
    ) async throws -> Transclusion {
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
    
    func fetchTranscludes(
        slashlinks: [Slashlink],
        owner: Peer?
    ) async -> [Slashlink: EntryStub] {
        // Cheap early exit if no slashlinks are requested
        guard slashlinks.count > 0 else {
            return [:]
        }

        var dict: [Slashlink: EntryStub] = [:]
        
        for link in slashlinks {
            let transclusion = try? await resolveAddresses(
                base: owner,
                link: link
            )

            guard let transclusion = transclusion else {
                continue
            }
            
            let address = Slashlink(
                peer: .did(transclusion.authorDid),
                slug: link.slug
            )

            guard let entry = try? database.readEntry(for: address) else {
                continue
            }
            
            if entry.address.isLocal {
                dict.updateValue(
                    entry,
                    forKey: Slashlink(slug: entry.address.slug)
                )
                continue
            }
            
            dict.updateValue(entry, forKey: transclusion.displayAddress)
        }
        
        return dict
    }

    func fetchTranscludes(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async -> [Slashlink: EntryStub] {
        await fetchTranscludes(
            slashlinks: slashlinks,
            owner: owner.address.peer
        )
    }

    nonisolated func fetchTranscludesPublisher(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) -> AnyPublisher<[Slashlink: EntryStub], Never> {
        Future.detached(priority: .utility) {
            await self.fetchTranscludes(
                slashlinks: slashlinks,
                owner: owner
            )
        }
        .eraseToAnyPublisher()
    }
}
