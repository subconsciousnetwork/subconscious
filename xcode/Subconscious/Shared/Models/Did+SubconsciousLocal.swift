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
    static let local = Did("did:subconscious:local")
}

extension Slashlink {
    /// Does this slashlink point to content saved to the local file system,
    /// rather than a sphere?
    var isLocal: Bool {
        switch self.peer {
        case .did(let did):
            return did == Did.local
        default:
            return false
        }
    }

    /// Get audience from slashlink
    func toAudience() -> Audience {
        switch self.peer {
        case .did(let did):
            return did == Did.local ? .local : .public
        case .petname:
            return .public
        case .none:
            return .public
        }
    }
}
