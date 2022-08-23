//
//  TraceryService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/25/22.
//

import Foundation
import Tracery

typealias TraceryRules = [String]
typealias TraceryGrammar = [String: TraceryRules]

struct RandomPromptGeist {
    private let database: DatabaseService
    private let tracery: Tracery

    init(
        database: DatabaseService,
        grammar: TraceryGrammar
    ) {
        self.database = database
        self.tracery = Tracery(rules: { grammar })
    }

    func expand() -> StoryPrompt? {
        guard let stub = database.readRandomEntry() else {
            return nil
        }
        let prompt = tracery.expand("#origin#")
        return StoryPrompt(entry: stub, prompt: prompt)
    }
}

extension RandomPromptGeist {
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
