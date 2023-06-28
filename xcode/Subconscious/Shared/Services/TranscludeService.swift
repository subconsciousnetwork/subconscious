//
//  TranscludeService.swift
//  Subconscious
//
//  Created by Ben Follington on 5/5/2023.
//

import Foundation
import Combine

actor TranscludeService {
    private var database: DatabaseService
    private var noosphere: NoosphereService
    
    init(database: DatabaseService, noosphere: NoosphereService) {
        self.database = database
        self.noosphere = noosphere
    }
    
    func fetchTranscludePreviews(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async throws -> [Slashlink: EntryStub] {
        let petname = owner.address.petname
        
        let slashlinks = slashlinks.map { address in
            guard case .petname(_) = address.peer else {
                // Rebase relative slashlinks to the owner's handle (if they have one)
                return Slashlink(peer: owner.address.peer, slug: address.slug)
            }
            
            return address
        }
        
        let entries = try database.listEntries(for: slashlinks)
        var dict: [Slashlink: EntryStub] = [:]
        
        for entry in entries {
            if entry.address.isLocal {
                dict.updateValue(entry, forKey: Slashlink(slug: entry.address.slug))
                continue
            }
            
            // Ensure links to the owner's content are relativized to match
            // the in-text representation
            let displayAddress = entry.address.relativizeIfNeeded(petname: petname)
            dict.updateValue(entry, forKey: displayAddress)
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
