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
}

actor TranscludeService {
    private var database: DatabaseService
    private var noosphere: NoosphereService
    
    init(database: DatabaseService, noosphere: NoosphereService) {
        self.database = database
        self.noosphere = noosphere
    }
    
    func resolveAddresses(base: Slashlink, link: Slashlink) async throws -> Transclusion {
        let address = link.rebaseIfNeeded(slashlink: base)
        let did = try await noosphere.resolve(peer: address.peer)
        
        return Transclusion(
            displayAddress: link,
            address: Slashlink(peer: .did(did), slug: address.slug)
        )
    }
    
    func fetchTranscludePreviews(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async throws -> [Slashlink: EntryStub] {
        var dict: [Slashlink: EntryStub] = [:]
        
        for link in slashlinks {
            let transclusion = try await resolveAddresses(base: owner.address, link: link)
            guard let entry = try database.readEntry(for: transclusion.address) else {
                continue
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
