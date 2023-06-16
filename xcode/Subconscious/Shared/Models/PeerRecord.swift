//
//  PeerRecord.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/18/23.
//

import Foundation

/// Represents a peer in the database
struct PeerRecord: Hashable {
    var petname: Petname
    var identity: Did
    var since: Cid?
    
    /// Update identity for this peer.
    // If identity changes for petname, then we set the version to `nil`,
    // since this new identity will have a new historical lineage.
    func update(identity: Did) -> Self {
        var this = self
        if identity != self.identity {
            this.since = nil
        }
        return this
    }
}
