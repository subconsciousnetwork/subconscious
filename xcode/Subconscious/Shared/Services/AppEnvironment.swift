//
//  AppEnvironment.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/7/21.
//

import Foundation
import os
import Combine

//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    let fileManager = FileManager.default
    let documentsUrl: URL
    let databaseUrl: URL
    let logger = Constants.logger
    let database: DatabaseEnvironment
    let documentService = DocumentService()
    
    init() {
        self.databaseUrl = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("database.sqlite")

        self.documentsUrl = fileManager.documentDirectoryUrl!
        
        self.database = DatabaseEnvironment(
            databaseUrl: databaseUrl,
            documentsUrl: documentsUrl,
            migrations: DatabaseEnvironment.getMigrations()
        )
    }
    
    //  FIXME: this just serves up static suggestions
    func fetchSuggestions(query: String) -> Future<[Suggestion], Never> {
        Future({ promise in
            var suggestions = [
                Suggestion.thread(
                    "If you have 70 notecards, you have a movie"
                ),
                Suggestion.thread(
                    "Tenuki"
                ),
                Suggestion.query(
                    "Notecard"
                ),
            ]
            if !query.isEmpty {
                suggestions.append(.create(query))
            }
            promise(.success(suggestions))
        })
    }
    
    //  FIXME: serves up static suggestions
    func fetchSuggestionTokens() -> Future<[String], Never> {
        Future({ promise in
            let suggestions = [
                "#log",
                "#idea",
                "#pattern",
                "#project",
                "#decision",
                "#quote",
                "#book",
                "#person"
            ]
            promise(.success(suggestions))
        })
    }
}
