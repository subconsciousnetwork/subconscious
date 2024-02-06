//
//  PromptOrchestrator.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/5/24.
//

import Foundation

enum PromptClassificationTag: Hashable {
    case journal
    case project
    case list
    case link
    case quote
    case heading
}

struct PromptClassification: Hashable, Comparable {
    static func < (
        lhs: PromptClassification,
        rhs: PromptClassification
    ) -> Bool {
        lhs.weight < rhs.weight
    }

    let tag: PromptClassificationTag
    let weight: CGFloat
}

typealias PromptClassifications = [PromptClassification]

extension PromptClassifications {
    func consolidate() -> PromptClassifications {
        // iterate over all entries and combine the scores of matching tags
        var consolidated: PromptClassifications = []
        for score in self {
            if let index = consolidated.firstIndex(where: { $0.tag == score.tag }) {
                consolidated[index] = PromptClassification(
                    tag: score.tag,
                    weight: consolidated[index].weight + score.weight
                )
            } else {
                consolidated.append(score)
            }
        }
        // Sort by weights, high to low
        consolidated.reverse()
        return consolidated
    }
}

struct PromptResult: Hashable, Comparable {
    static func < (lhs: PromptResult, rhs: PromptResult) -> Bool {
        lhs.weight < rhs.weight
    }

    let result: String
    let weight: CGFloat
}

typealias PromptResults = [PromptResult]

/// Protocol to implement a classifier
protocol PromptClassifierProtocol {
    func classify(_ input: String) async -> PromptClassifications
}

struct SubtextClassifier: PromptClassifierProtocol {
    let route: (Subtext, String) async -> PromptClassifications

    init(
        route: @escaping (Subtext, String) -> PromptClassifications
    ) {
        self.route = route
    }

    func classify(_ input: String) async -> PromptClassifications {
        let dom = Subtext(markup: input)
        return await self.route(dom, input)
    }
}

struct RegexClassifier<Output>: PromptClassifierProtocol {
    let pattern: Regex<Output>
    let route: ([Regex<Output>.Match], String) async -> PromptClassifications

    init(
        _ pattern: Regex<Output>,
        route: @escaping ([Regex<Output>.Match], String) -> PromptClassifications
    ) {
        self.pattern = pattern.ignoresCase()
        self.route = route
    }

    func classify(_ input: String) async -> PromptClassifications {
        let matches = input.matches(of: pattern)
        
        guard !matches.isEmpty else {
            return []
        }
        
        return await self.route(matches, input)
    }
}

/// Protocol to implement a route
protocol PromptRouteProtocol {
    func route(
        input: String,
        classifications: PromptClassifications
    ) async -> [PromptResult]
}

/// Default implementation of a route that just takes a closure
struct PromptRoute: PromptRouteProtocol {
    private var _route: (String, PromptClassifications) async -> [PromptResult]

    init(
        _ route: @Sendable @escaping (
            String,
            PromptClassifications
        ) async -> [PromptResult]
    ) {
        self._route = route
    }

    func route(
        input: String,
        classifications: PromptClassifications
    ) async -> [PromptResult] {
        await _route(input, classifications)
    }
}

struct PromptOrchestrator {
    private var classifiers: [PromptClassifierProtocol]
    private var routes: [PromptRouteProtocol]

    init(
        classifiers: [PromptClassifierProtocol] = [],
        routes: [PromptRouteProtocol] = []
    ) {
        self.classifiers = classifiers
        self.routes = routes
    }

    mutating func classifier(_ classifier: PromptClassifierProtocol) {
        self.classifiers.append(classifier)
    }

    mutating func route(_ route: PromptRouteProtocol) {
        self.routes.append(route)
    }

    /// Match input against disambiguators, returning up to `max` matches
    /// for input.
    func generate(
        _ input: String,
        max maxResults: Int = 5
    ) async -> [PromptResult] {
        var classifications: PromptClassifications = []
        for classifier in classifiers {
            let classification = await classifier.classify(input)
            classifications.append(contentsOf: classification)
        }
        let consolidatedClassifications = classifications.consolidate()
        var results: [PromptResult] = []
        for route in routes {
            let routeResults = await route.route(
                input: input,
                classifications: consolidatedClassifications
            )
            for result in routeResults {
                results.append(result)
                if results.count >= maxResults {
                    return results.reversed()
                }
            }
        }
        return results.reversed()
    }
}
