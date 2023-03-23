//
//  SlashlinkLookupService.swift
//  Subconscious
//
//  Created by Ben Follington on 23/3/2023.
//

import Foundation
import Combine

class SlashlinkLookupService {
    var database: DatabaseService
    private var cache: Dictionary<Slashlink, EntryStub>
    
    init(database: DatabaseService) {
        self.database = database
        self.cache = Dictionary()
    }
    
    func listEntriesForSlashlinks(slashlinks: [Slashlink]) throws -> Dictionary<Slashlink, EntryStub> {
        // Check for cached data
        let cacheHits =
            slashlinks.map { s in
                cache[s]
            }
            .compactMap { value in value }
        
        // Do we have it all? Early return
        if cacheHits.count == slashlinks.count {
            return cache
        }
        
        // Otherwise, only look up the cache misses
        let remainingLinks = slashlinks.filter { s in cache[s] == nil }
        let result = try self.database.listEntriesForSlashlinks(slashlinks: remainingLinks)
        
        // Cache for the future
        for link in result {
            cache[link.address.toSlashlink()] = link
        }
        
        // Combine the two sets of results
        return cache
    }
    
    func listEntriesForSlashlinksAsync(slashlinks: [Slashlink]) -> AnyPublisher<Dictionary<Slashlink, EntryStub>, Error> {
        CombineUtilities.async(qos: .default) {
            return try self.listEntriesForSlashlinks(slashlinks: slashlinks)
        }
    }
}
