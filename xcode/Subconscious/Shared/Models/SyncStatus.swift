//
//  SyncStatus.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/23/23.
//

import Foundation

/// An enum representing sync state
enum SyncStatus: Hashable, Codable {
    case initial
    case syncing
    case synced
    case failed(_ message: String)
    
    // Is in a completed state?
    var isComplete: Bool {
        switch self {
        case .synced:
            return true
        case .failed:
            return true
        default:
            return false
        }
    }
}
