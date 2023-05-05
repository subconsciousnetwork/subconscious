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
    
    func fetchTranscludes(
        slashlinks: [Slashlink]
    ) async throws -> [Slashlink: EntryStub] {
        let entries = try database.listEntriesForSlashlinks(slashlinks: slashlinks)
        
        return
            Dictionary(
                entries.map { entry in
                    (entry.address.toSlashlink(), entry)
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
