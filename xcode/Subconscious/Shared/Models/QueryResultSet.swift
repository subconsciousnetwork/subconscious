//
//  QueryResultSet.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/9/21.
//

/// Represents a set of results for a given query string
struct QueryResultSet {
    var query: String = ""
    var results: [Result]
}

let EmptyQueryResultSet = QueryResultSet(
    query: "",
    results: []
)
