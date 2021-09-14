//
//  Suggestions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/21.
//

import Foundation

struct ResultSuggestion: Equatable, Hashable, Identifiable {
    var id = UUID()
    var query: String
}

struct QuerySuggestion: Equatable, Hashable, Identifiable {
    var id = UUID()
    var query: String
}

enum Suggestion: Equatable, Hashable, Identifiable {
    case result(ResultSuggestion)
    case query(QuerySuggestion)

    var id: UUID {
        switch self {
        case .result(let suggestion):
            return suggestion.id
        case .query(let suggestion):
            return suggestion.id
        }
    }

    var query: String {
        switch self {
        case .result(let result):
            return result.query
        case .query(let query):
            return query.query
        }
    }
}

struct Suggestions: Equatable, Hashable {
    static let Empty = Suggestions()
    var query: String = ""
    var suggestions: [Suggestion] = []
}
