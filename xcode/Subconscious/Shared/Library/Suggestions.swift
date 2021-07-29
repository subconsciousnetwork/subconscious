//
//  Suggestions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/21.
//

import Foundation

struct ResultSuggestion: Equatable, Hashable, Identifiable {
    var id: String {
        "result/\(query.hash)"
    }
    var query: String
}

struct QuerySuggestion: Equatable, Hashable, Identifiable {
    var id: String {
        "query/\(query.hash)"
    }
    var query: String
}

struct Suggestions: Equatable, Hashable {
    static let Empty = Suggestions()
    var query: String = ""
    var results: [ResultSuggestion] = []
    var queries: [QuerySuggestion] = []
}
