//
//  Did+SubconsciousLocalFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/1/23.
//
//  Extends Did to include a the non-standard `did:subconscious:local`.
//  We keep the extension here so that Did is not complected with this
//  app-specific nonstandard concept.

extension Did {
    /// A non-standard did we use to represent the local file system.
    static let local = Did("did:subconscious:local")!
}

extension Slashlink {
    /// Does this slashlink point to content saved to the local file system,
    /// rather than a sphere?
    var isLocal: Bool {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return true
        default:
            return false
        }
    }
    
    /// Get audience from slashlink
    func toAudience() -> Audience {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return .local
        case .did:
            return .public
        case .petname:
            return .public
        case .none:
            return .public
        }
    }
    
    /// Check if slashlink points to content that belongs to us.
    var isOurs: Bool {
        switch self.peer {
        case .did(let did) where did == Did.local:
            return true
        case .did:
            return false
        case .petname:
            return false
        case .none:
            return true
        }
    }
}
