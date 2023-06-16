//
//  NoospherePeerChange.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/18/23.
//

import Foundation

extension Noosphere {
    /// Describes a peer change in our address book
    public enum PeerChange: Hashable {
        /// Petname was added or updated within address book
        case update(Peer)
        /// Petname was removed from address book
        case remove(petname: Petname)
    }
}
