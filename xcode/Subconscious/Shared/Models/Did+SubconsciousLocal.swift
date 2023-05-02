//
//  Did+SubconsciousLocalFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/1/23.
//

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
}
