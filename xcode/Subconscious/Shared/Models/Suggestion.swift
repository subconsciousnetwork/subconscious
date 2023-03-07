//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable {
    case memo(address: MemoAddress, fallback: String = "")
    case createLocalMemo(slug: Slug? = nil, fallback: String = "")
    case createPublicMemo(slug: Slug? = nil, fallback: String = "")
    case random
    
    var fallback: String? {
        switch self {
        case let .memo(_, fallback):
            return fallback
        case let .createLocalMemo(_, fallback):
            return fallback
        case let .createPublicMemo(_, fallback):
            return fallback
        case .random:
            return nil
        }
    }

    var address: MemoAddress? {
        switch self {
        case .memo(let address, _):
            return address
        case let .createLocalMemo(slug, _):
            return slug?.toLocalMemoAddress()
        case let .createPublicMemo(slug, _):
            return slug?.toPublicMemoAddress()
        case .random:
            return nil
        }
    }
}
