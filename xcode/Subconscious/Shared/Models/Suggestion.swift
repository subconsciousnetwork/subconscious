//
//  Suggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/19/21.
//

import Foundation

enum Suggestion: Hashable {
    case memo(address: Slashlink, fallback: String = "")
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

    var address: Slashlink? {
        switch self {
        case .memo(let address, _):
            return address
        case let .createLocalMemo(slug, _):
            return slug?.toLocalSlashlink()
        case let .createPublicMemo(slug, _):
            return slug?.toSlashlink()
        case .random:
            return nil
        }
    }
}
