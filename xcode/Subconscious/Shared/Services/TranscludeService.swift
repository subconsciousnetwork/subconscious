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
    
    init(database: DatabaseService) {
        self.database = database
    }
    
    func fetchTranscludes(slashlinks: [Slashlink]) async throws -> Dictionary<Slashlink, EntryStub> {
        let entries = try database.listEntriesForSlashlinks(slashlinks: slashlinks)
        
        var dict = Dictionary<Slashlink, EntryStub>()
        for entry in entries {
            dict[entry.address.toSlashlink()] = entry
        }
        
        return dict
    }
    
    nonisolated func fetchTranscludesPublisher(
        slashlinks: [Slashlink]
    ) -> AnyPublisher<Dictionary<Slashlink, EntryStub>, Error> {
        Future.detached(priority: .utility) {
            try await self.fetchTranscludes(slashlinks: slashlinks)
        }
        .eraseToAnyPublisher()
    }
}
