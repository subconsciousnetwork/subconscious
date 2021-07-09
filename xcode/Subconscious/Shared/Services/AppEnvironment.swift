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
    
    init() {
        self.databaseUrl = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("database.sqlite")

        self.documentsUrl = fileManager.documentDirectoryUrl!
        
        self.database = try! DatabaseEnvironment(
            databaseUrl: databaseUrl,
            documentsUrl: documentsUrl,
            migrations: DatabaseEnvironment.getMigrations()
        )
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
