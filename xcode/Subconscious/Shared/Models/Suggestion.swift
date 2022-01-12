//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable, CustomStringConvertible {
    case entry(EntryLink)
    case search(EntryLink)

    var stub: EntryLink {
        switch self {
        case let .entry(stub):
            return stub
        case let .search(stub):
            return stub
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
