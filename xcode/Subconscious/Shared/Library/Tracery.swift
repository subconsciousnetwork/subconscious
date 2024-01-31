//
//  MicroTracery.swift
//  SubconsciousExperiments
//
//  Created by Gordon Brander on 1/29/24.
//

public typealias Grammar = [String: [String]]

/// Create a Tracery with an optional registry of modifiers
public struct Tracery {
    private static let token = /#(\w+)(\.(\w+))?#/

    private var modifiers: [String: (String) -> String]
    private let maxDepth = 500

    /// Create a Tracery parser
    /// - Parameters
    ///   - modifiers: a dictionary of named functions that can be used to
    ///     post-process Tracery tokens.
    public init(
        modifiers: [String: (String) -> String] = [:]
    ) {
        self.modifiers = modifiers
    }

    /// Recursively flatten a grammar. Internal.
    /// Call by public method `flatten(grammar:start:)`.
    /// - Parameters
    ///   - depth: keeps track of recursion depth so we can exit if exceeding
    ///   - grammar: the Tracery grammar
    ///   - start: the start string
    /// - Returns: the flattened string
    private func flatten(
        depth: Int,
        grammar: Grammar,
        start: String = "#start#"
    ) -> String {
        // Stop flattening at depth > max
        guard depth <= maxDepth else {
            return start
        }
        return start.replacing(Self.token, with: { match in
            let key = String(match.1)
            guard let value = grammar[key]?.randomElement() else {
                return match.0
            }
            guard
                let modifierKey = match.3?.toString(),
                let postprocess = modifiers[modifierKey]
            else {
                return flatten(
                    depth: depth + 1,
                    grammar: grammar,
                    start: value
                ).toSubstring()
            }
            return postprocess(
                flatten(
                    depth: depth + 1,
                    grammar: grammar,
                    start: value
                )
            ).toSubstring()
        })
    }

    /// Flatten the start string using the given Tracery grammar.
    /// - Parameters
    ///   - grammar: the Tracery grammar
    ///   - start: the start string
    /// - Returns: the flattened string
    public func flatten(
        grammar: Grammar,
        start: String = "#start#"
    ) -> String {
        flatten(depth: 0, grammar: grammar, start: start)
    }
}
