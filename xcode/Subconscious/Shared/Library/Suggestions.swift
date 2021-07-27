//
//  Suggestions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/21.
//

import Foundation

struct SearchSuggestion: Equatable, Hashable, Identifiable {
    var id: String {
        "search-suggestion/\(query.hash)"
    }
    var query: String
}

enum ActionSuggestion: Equatable, Hashable {
    case edit(url: URL, title: String)
    case create(_ text: String)
}

extension ActionSuggestion: Identifiable {
    var id: String {
        switch self {
        case .edit(_, let title):
            return "entry/\(title.hash)"
        case .create(let text):
            return "create/\(text.hash)"
        }
    }
}

extension ActionSuggestion: CustomStringConvertible {
    var description: String {
        switch self {
        case .edit(_, let title):
            return title
        case .create(let text):
            return text
        }
    }
}

struct Suggestions: Equatable, Hashable {
    var searches: [SearchSuggestion] = []
    var actions: [ActionSuggestion] = []
}
