//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable, Identifiable {
    case entry(EntryLink)
    case search(EntryLink)
    case journal(EntryLink)
    case random

    var id: String {
        switch self {
        case let .entry(link):
            return "entry/\(link.id)"
        case let .search(link):
            return "search/\(link.id)"
        case let .journal(link):
            return "journal/\(link.id)"
        case .random:
            return "random"
        }
    }
}
