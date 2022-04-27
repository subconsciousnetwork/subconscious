//
//  RenameSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

enum RenameSuggestion:
    Hashable,
    Equatable,
    Identifiable,
    CustomStringConvertible
{
    case rename(EntryLink)
    case merge(EntryLink)

    var id: String {
        switch self {
        case let .rename(link):
            return "rename/\(link.id)"
        case let .merge(link):
            return "merge/\(link.id)"
        }
    }

    var description: String {
        switch self {
        case let .rename(stub):
            return stub.title
        case let .merge(stub):
            return stub.title
        }
    }
}
