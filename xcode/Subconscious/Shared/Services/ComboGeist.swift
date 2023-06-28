//
//  ComboGeist.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/9/2022.
//

import Foundation
import Tracery

struct ComboGeist: Geist {
    private let database: DatabaseService
    private let tracery: Tracery

    init(database: DatabaseService, grammar: TraceryGrammar) {
        self.database = database
        self.tracery = Tracery(rules: { grammar })
    }

    func ask(query: String) -> Story? {
        let prompt = tracery.expand("#combo_followup#")
        guard let stubA = database.readRandomEntry(owner: nil) else {
            return nil
        }
        guard let stubB = database.readRandomEntry(owner: nil) else {
            return nil
        }
        return Story.combo(StoryCombo(prompt: prompt, entryA: stubA, entryB: stubB))
    }
}

extension ComboGeist {
    init(
        database: DatabaseService,
        data: Data
    ) throws {
        let decoder = JSONDecoder()
        let grammar = try decoder.decode(TraceryGrammar.self, from: data)
        self.init(
            database: database,
            grammar: grammar
        )
    }
}
