//
//  ComboGeist.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/9/2022.
//

import Foundation

struct ComboGeist: Geist {
    private let database: DatabaseService

    init(database: DatabaseService) {
        self.database = database
    }

    func ask(query: String) -> Story? {
        guard let stubA = database.readRandomEntry() else {
            return nil
        }
        guard let stubB = database.readRandomEntry() else {
            return nil
        }
        return Story.combo(StoryCombo(entryA: stubA, entryB: stubB))
    }
}

extension ComboGeist {
    init(
        database: DatabaseService,
        data: Data
    ) throws {
        self.init(database: database)
    }
}
