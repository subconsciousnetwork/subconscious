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

enum DisambiguatorTag {
    case journal(_ score: CGFloat)
    case project(_ score: CGFloat)
    case list(_ score: CGFloat, _ count: Int)
}

typealias DisambiguatorMatch = [DisambiguatorTag]

protocol TraceryDisambiguatorRoute {
    func classify(_ input: String) async -> DisambiguatorMatch
}

struct RegexRoute<Output>: TraceryDisambiguatorRoute {
    let pattern: Regex<Output>
    let route: (Regex<Output>.Match, String) async -> DisambiguatorMatch

    init(
        _ pattern: Regex<Output>,
        route: @escaping (Regex<Output>.Match, String) -> DisambiguatorMatch
    ) {
        self.pattern = pattern.ignoresCase()
        self.route = route
    }

    func classify(_ input: String) async -> DisambiguatorMatch {
        guard let match = try? pattern.firstMatch(in: input) else {
            return []
        }
        return await self.route(match, input)
    }
}

/// A router for Tracery Grammars
struct TraceryDisambiguator {
    var classifiers: [TraceryDisambiguatorRoute]

    init(classifiers: [TraceryDisambiguatorRoute] = []) {
        self.classifiers = classifiers
    }

    mutating func route(_ route: TraceryDisambiguatorRoute) {
        self.classifiers.append(route)
    }

    /// Match input against disambiguators, returning up to `max` matches
    /// for input.
    func match(
        _ input: String,
        max maxResults: Int = 5
    ) async -> DisambiguatorMatch {
        var results: DisambiguatorMatch = []
        for route in classifiers {
            let classification = await route.classify(input)
            results.append(contentsOf: classification)
        }
        return results
    }
}
