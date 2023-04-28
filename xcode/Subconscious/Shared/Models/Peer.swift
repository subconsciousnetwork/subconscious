//
//  Peer.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/28/23.
//

import Foundation

/// A sphere peer. May be either a Did or a Petname.
public enum Peer: Hashable, Codable {
    case did(Did)
    case petname(Petname)
    
    /// An absolute peer is a peer that is a did.
    /// A "relative" peer is a peer that is a petname.
    var isAbsolute: Bool {
        switch self {
        case .did:
            return true
        case .petname:
            return false
        }
    }
}
