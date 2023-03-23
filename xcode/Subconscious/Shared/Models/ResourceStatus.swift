//
//  ResourceStatus.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/23/23.
//

import Foundation

/// An enum representing a resource state with a lifecycle that includes setup,
/// complete and failed states.
/// Examples include database migration and sync.
enum ResourceStatus: Hashable, Codable {
    case initial
    case pending
    case succeeded
    case failed(_ message: String)
    
    // Is in a completed state?
    var isResolved: Bool {
        switch self {
        case .succeeded:
            return true
        case .failed:
            return true
        default:
            return false
        }
    }
}
