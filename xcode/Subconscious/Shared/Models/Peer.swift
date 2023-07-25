//
//  Peer.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/28/23.
//

import Foundation

/// A sphere peer. May be either a Did or a Petname.
public enum Peer: Hashable, Codable, CustomStringConvertible {
    case did(Did)
    case petname(Petname)
    
    public var description: String {
        switch self {
        case .did(let did):
            return did.description
        case .petname(let petname):
            return petname.description
        }
    }
    
    public var verbatim: String {
        switch self {
        case .did(let did):
            return did.description
        case .petname(let petname):
            return petname.verbatim
        }
    }
    
    /// Get markup form of peer (Either DID or petname)
    public var markup: String {
        switch self {
        case .did(let did) where did.isLocal:
            return ""
        case .did(let did):
            return did.description
        case .petname(let petname):
            return petname.markup
        }
    }
    
    /// Get verbatim markup for peer.
    /// May be used in the editor to preserve casing information.
    public var verbatimMarkup: String {
        switch self {
        case .did(let did):
            return did.description
        case .petname(let petname):
            return petname.verbatimMarkup
        }
    }
    
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
