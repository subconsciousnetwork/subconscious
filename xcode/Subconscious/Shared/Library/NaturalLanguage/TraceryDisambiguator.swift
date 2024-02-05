//
//  TraceryDisambiguator.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/5/24.
//

import Foundation

struct TraceryContext: Hashable {
    var start: String = "#start#"
    var grammar: Grammar = [:]
}

protocol TraceryDisambiguatorRoute {
    func match(_ input: String) -> TraceryContext?
}

struct RegexRoute<Output>: TraceryDisambiguatorRoute {
    let pattern: Regex<Output>
    let route: (Regex<Output>.Match, String) -> TraceryContext?

    init(
        _ pattern: Regex<Output>,
        route: @escaping (Regex<Output>.Match, String) -> TraceryContext?
    ) {
        self.pattern = pattern.ignoresCase()
        self.route = route
    }

    func match(_ input: String) -> TraceryContext? {
        guard let match = try? pattern.firstMatch(in: input) else {
            return nil
        }
        return self.route(match, input)
    }
}

/// A router for Tracery Grammars
struct TraceryDisambiguator {
    var routes: [TraceryDisambiguatorRoute]

    init(routes: [TraceryDisambiguatorRoute] = []) {
        self.routes = routes
    }

    mutating func route(_ route: TraceryDisambiguatorRoute) {
        self.routes.append(route)
    }

    /// Match input against disambiguators, returning up to `max` matches
    /// for input.
    func match(_ input: String, max maxResults: Int = 5) -> [TraceryContext] {
        var results: [TraceryContext] = []
        for route in routes {
            if let result = route.match(input) {
                results.append(result)
                if results.count >= maxResults {
                    return results
                }
            }
        }
        return results
    }
}
