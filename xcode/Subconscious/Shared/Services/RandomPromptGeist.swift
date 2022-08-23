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

struct StoryPrompt: Hashable, Identifiable, CustomStringConvertible {
    var entry: EntryStub
    var prompt: String

    var description: String {
        """
        \(prompt)
        
        \(String(describing: entry))
        """
    }

    var id: String {
        "/story/prompt/\(entry.slug)"
    }
}

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

    /// Convenience initializer that reads JSON from bundle
    init(
        database: DatabaseService,
        resource: String,
        withExtension ext: String = "json"
    ) throws {
        let data = try Bundle.main.read(resource: resource, withExtension: ext)
        try self.init(
            database: database,
            data: data
        )
    }
}
