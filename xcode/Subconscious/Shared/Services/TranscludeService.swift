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
    
    func fetchTranscludes(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) async throws -> [Slashlink: EntryStub] {
        let petname = owner.address.petname
        
        let slashlinks = slashlinks.map { s in
            if case let .petname(basePetname) = s.peer {
                return s.rebaseIfNeeded(petname: basePetname)
            } else {
                return Slashlink(peer: owner.address.peer, slug: s.slug)
            }
        }
        
        let entries = try database.listEntries(for: slashlinks, owner: petname)
        
        return
            Dictionary(
                entries.map { entry in
                    if entry.address.isLocal {
                        return (Slashlink(slug: entry.address.slug), entry)
                    }
                    
                    return (entry.address.relativizeIfNeeded(petname: petname), entry)
                },
                uniquingKeysWith: { a, b in a}
            )
    }

    
    nonisolated func fetchTranscludesPublisher(
        slashlinks: [Slashlink],
        owner: UserProfile
    ) -> AnyPublisher<[Slashlink: EntryStub], Error> {
        Future.detached(priority: .utility) {
            try await self.fetchTranscludes(slashlinks: slashlinks, owner: owner)
        }
        .eraseToAnyPublisher()
    }
}
