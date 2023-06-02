//
//  ResolutionStatus.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 22/5/2023.
//

import Foundation

/// An enum representing a remote resource which may or may not be able to be resolved.
/// Examples include user profiles.
enum ResolutionStatus: Equatable, Hashable, Codable {
    case unresolved
    case pending
    case resolved(_ cid: Cid)
    
    var isReady: Bool {
        switch self {
        case .resolved(_):
            return true
        case _:
            return false
        }
    }
}
