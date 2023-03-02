//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable {
    case memo(address: MemoAddress, title: String)
    case create(address: MemoAddress? = nil, title: String? = nil)
    case random
    
    var query: String? {
        switch self {
        case let .memo(_, title):
            return title
        case let .create(address, title):
            return Prose.deriveTitle(address: address, title: title)
        case .random:
            return nil
        }
    }

    var address: MemoAddress? {
        switch self {
        case .memo(let address, _):
            return address
        case .create(let address, _):
            return address
        case .random:
            return nil
        }
    }
}
