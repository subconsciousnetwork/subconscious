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

struct TraceryGeistService {
    private let tracery: Tracery

    init(grammar: TraceryGrammar) {
        self.tracery = Tracery(rules: { grammar })
    }

    func expand() -> String {
        tracery.expand("#origin#")
    }
}

extension TraceryGeistService {
    init(data: Data) throws {
        let decoder = JSONDecoder()
        let grammar = try decoder.decode(TraceryGrammar.self, from: data)
        self.init(grammar: grammar)
    }

    /// Convenience initializer that reads JSON from bundle
    init(resource: String, withExtension ext: String = "json") throws {
        let data = try Bundle.main.read(resource: resource, withExtension: ext)
        try self.init(data: data)
    }
}
