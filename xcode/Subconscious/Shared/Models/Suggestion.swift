//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable {
    case memo(address: MemoAddress, fallback: String = "")
    case create(address: MemoAddress? = nil, fallback: String = "")
    case random
    
    var fallback: String? {
        switch self {
        case let .memo(_, fallback):
            return fallback
        case let .create(_, fallback):
            return fallback
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
