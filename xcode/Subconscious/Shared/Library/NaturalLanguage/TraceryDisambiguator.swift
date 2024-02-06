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
    case journal
    case project
    case list
    case link
    case quote
    case heading
}

struct DisambiguatorScore {
    let tag: DisambiguatorTag
    let weight: CGFloat
}

typealias DisambiguatorMatch = [DisambiguatorScore]

extension DisambiguatorMatch {
    func consolidate() -> DisambiguatorMatch {
        // iterate over all entries and combine the scores of matching tags
        var consolidated: DisambiguatorMatch = []
        for score in self {
            if let index = consolidated.firstIndex(where: { $0.tag == score.tag }) {
                consolidated[index] = DisambiguatorScore(
                    tag: score.tag,
                    weight: consolidated[index].weight + score.weight
                )
            } else {
                consolidated.append(score)
            }
        }
        
        return consolidated
    }
}

protocol TraceryDisambiguatorRoute {
    func classify(_ input: String) async -> DisambiguatorMatch
}

struct SubtextRoute: TraceryDisambiguatorRoute {
    let route: (Subtext, String) async -> DisambiguatorMatch

    init(
        route: @escaping (Subtext, String) -> DisambiguatorMatch
    ) {
        self.route = route
    }

    func classify(_ input: String) async -> DisambiguatorMatch {
        let dom = Subtext(markup: input)
        return await self.route(dom, input)
    }
}

struct RegexRoute<Output>: TraceryDisambiguatorRoute {
    let pattern: Regex<Output>
    let route: ([Regex<Output>.Match], String) async -> DisambiguatorMatch

    init(
        _ pattern: Regex<Output>,
        route: @escaping ([Regex<Output>.Match], String) -> DisambiguatorMatch
    ) {
        self.pattern = pattern.ignoresCase()
        self.route = route
    }

    func classify(_ input: String) async -> DisambiguatorMatch {
        let matches = input.matches(of: pattern)
        
        guard !matches.isEmpty else {
            return []
        }
        
        return await self.route(matches, input)
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
        return results.consolidate()
    }
}
