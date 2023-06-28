//
//  QueryPromptGeist.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/14/22.
//

import Foundation
import Tracery

struct QueryPromptGeist: Geist {
    typealias TraceryRules = [String]
    typealias TraceryGrammar = [String: TraceryRules]

    private let origin: String
    private let database: DatabaseService
    private let tracery: Tracery
    private let query: String

    init(
        database: DatabaseService,
        grammar: TraceryGrammar,
        query: String,
        origin: String = "#origin#"
    ) {
        self.database = database
        self.tracery = Tracery(rules: { grammar })
        self.query = query
        self.origin = origin
    }

    func ask(query: String) -> Story? {
        guard
            let stub = database.readRandomEntryMatching(query: self.query, owner: nil)
        else {
            return nil
        }
        let prompt = tracery.expand(self.origin)
        return Story.prompt(StoryPrompt(entry: stub, prompt: prompt))
    }
}

extension QueryPromptGeist {
    init(
        database: DatabaseService,
        data: Data,
        query: String
    ) throws {
        let decoder = JSONDecoder()
        let grammar = try decoder.decode(TraceryGrammar.self, from: data)
        self.init(
            database: database,
            grammar: grammar,
            query: query
        )
    }
}
