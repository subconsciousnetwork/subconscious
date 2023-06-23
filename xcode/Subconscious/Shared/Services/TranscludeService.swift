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
        slashlinks: [Slashlink]
    ) async throws -> [Slashlink: EntryStub] {
        let identity = try await noosphere.identity()
        let entries = try database.listEntries(for: slashlinks, owner: identity)
        
        return
            Dictionary(
                entries.map { entry in
                    if entry.address.isLocal {
                        return (Slashlink(slug: entry.address.slug), entry)
                    }
                    
                    return (entry.address, entry)
                },
                uniquingKeysWith: { a, b in a}
            )
    }

    
    nonisolated func fetchTranscludesPublisher(
        slashlinks: [Slashlink]
    ) -> AnyPublisher<[Slashlink: EntryStub], Error> {
        Future.detached(priority: .utility) {
            try await self.fetchTranscludes(slashlinks: slashlinks)
        }
        .eraseToAnyPublisher()
    }
}
