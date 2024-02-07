//
//  PromptOrchestrator.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/5/24.
//

import Foundation
import NaturalLanguage

enum PromptClassificationTag: Hashable {
    case journal
    case project
    case question
    case list
    case link
    case quote
    case heading
    case date
    case noun(_ text: String)
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

/// Protocol to implement a classifier
protocol PromptClassifierProtocol {
    func classify(_ input: String) async -> PromptClassifications
}

struct KeywordClassifier: PromptClassifierProtocol {
    let route: ([String], String) async -> PromptClassifications
    
    init(
        route: @escaping ([String], String) -> PromptClassifications
    ) {
        self.route = route
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.noun, .personalName, .placeName, .organizationName]

        var keywords = [String]()
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) {
            tag,
            tokenRange in
            if let tag = tag,
               tags.contains(tag) {
                let keyword = String(text[tokenRange])
                keywords.append(keyword)
            }
            return true
        }

        return keywords
    }
    
    func classify(_ input: String) async -> PromptClassifications {
        let keywords = extractKeywords(from: input)
        return await self.route(keywords, input)
    }
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

/// Compose a collection of classifiers into a single classifier that returns
/// a consolidated collection of classifications.
struct PromptClassifier: PromptClassifierProtocol {
    private var classifiers: [PromptClassifierProtocol]

    init(classifiers: [PromptClassifierProtocol] = []) {
        self.classifiers = classifiers
    }

    /// Add a classifier, mutating this instance
    mutating func classifier(
        _ classifier: PromptClassifierProtocol
    ) {
        self.classifiers.append(classifier)
    }

    func classify(_ input: String) async -> PromptClassifications {
        var classifications: PromptClassifications = []
        for classifier in classifiers {
            let classification = await classifier.classify(input)
            classifications.append(contentsOf: classification)
        }
        return classifications.consolidate()
    }
}

/// The request context for prompt routes
struct PromptRouteRequest {
    var process: (String) async -> String?
    var input: String
    var classifications: PromptClassifications
}

/// Protocol to implement a route
protocol PromptRouteProtocol {
    func route(_ context: PromptRouteRequest) async -> String?
}

/// Default implementation of a route that just takes a closure
struct PromptRoute: PromptRouteProtocol {
    private var _route: (PromptRouteRequest) async -> String?

    init(
        _ route: @Sendable @escaping (PromptRouteRequest) async -> String?
    ) {
        self._route = route
    }

    func route(_ context: PromptRouteRequest) async -> String? {
        await _route(context)
    }
}

/// A prompt router request is intended to live for the lifetime of a single
/// router processing request.
actor PromptRouterRequest {
    /// An arbitrary depth at which we stop checking routes and return nil.
    /// This number should be generous, but small. If you exceed it, you're
    /// probably doing something wrong.
    private let maxDepth = 500
    /// The number of times this actor's `process` method has been called.
    /// This includes subsequent routes, and also recursive calls.
    private var depth = 0

    private var routes: [PromptRouteProtocol]
    private var classifier: PromptClassifierProtocol

    init(
        routes: [PromptRouteProtocol] = [],
        classifier: PromptClassifierProtocol
    ) {
        self.routes = routes
        self.classifier = classifier
    }

    /// Runs each route in order, returning the first result.
    /// Routes may to recursively process input with this router using the
    /// `process` function on the request struct passed to the route.
    /// A router request instance can recurse like this up to a maximum safe
    /// recursion depth. If that recursion depth is exceeded, this method
    /// returns nil.
    /// - Returns result or nil if no result, or safe recursion depth reached
    func process(_ input: String) async -> String? {
        self.depth = depth + 1
        // Exit if recursion limit has been reached for this request
        if depth > maxDepth {
            return nil
        }
        let classifications = await classifier.classify(input)
        let request = PromptRouteRequest(
            process: self.process,
            input: input,
            classifications: classifications
        )
        // Try each route in succession until we get a match
        for route in routes {
            if let result = await route.route(request) {
                return result
            }
        }
        return nil
    }
}

/// Combine a series of routes into a router for inputs
/// The first route producing a match is used.
/// Routes are processed in order. More specific routes should precede more
/// general ones.
/// Tip: routes can consider recursively calling the router with new input.
struct PromptRouter {
    private var routes: [PromptRouteProtocol]
    private var classifier: PromptClassifierProtocol

    init(
        routes: [PromptRouteProtocol] = [],
        classifier: PromptClassifierProtocol
    ) {
        self.routes = routes
        self.classifier = classifier
    }

    /// Add a route, mutating this instance
    mutating func route(_ route: PromptRouteProtocol) {
        self.routes.append(route)
    }

    /// Pipe input through a succession of routes until a match is found
    func process(_ input: String) async -> String? {
        let request = PromptRouterRequest(
            routes: routes,
            classifier: classifier
        )
        return await request.process(input)
    }
}
