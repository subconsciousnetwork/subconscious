//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable, Identifiable, CustomStringConvertible {
    case entry(EntryLink)
    case search(EntryLink)

    var id: String {
        switch self {
        case let .entry(link):
            return "entry/\(link.id)"
        case let .search(link):
            return "search/\(link.id)"
        }
    }

    var description: String {
        switch self {
        case let .entry(stub):
            return stub.title
        case let .search(stub):
            return stub.title
        }
    }
}
