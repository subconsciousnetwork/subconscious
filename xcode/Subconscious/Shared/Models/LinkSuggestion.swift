//
//  LinkSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

enum LinkSuggestion: Hashable, Identifiable, CustomStringConvertible {
    case entry(EntryLink)
    case new(EntryLink)

    var id: String {
        switch self {
        case let .entry(link):
            return "entry/\(link.id)"
        case let .new(link):
            return "new/\(link.id)"
        }
    }

    var description: String {
        switch self {
        case let .entry(stub):
            return stub.title
        case let .new(stub):
            return stub.title
        }
    }
}
