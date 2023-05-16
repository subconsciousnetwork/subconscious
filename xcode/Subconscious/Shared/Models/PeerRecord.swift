//
//  SphereSyncInfoRecord.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/12/23.
//

import Foundation

/// Describes a sphere identity and petname at a specific version
struct PeerRecord: Hashable, Codable {
    /// Petname assigned to sphere
    var petname: Petname
    /// DID of sphere
    var identity: Did
    /// Sphere version
    var version: Cid?
}
