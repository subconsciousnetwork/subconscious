//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable, CustomStringConvertible {
    case entry(Stub)
    case search(Stub)

    var description: String {
        switch self {
        case let .entry(stub):
            return stub.title
        case let .search(stub):
            return stub.title
        }
    }
}
