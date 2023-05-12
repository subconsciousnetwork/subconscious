//
//  SphereSyncInfoRecord.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/12/23.
//

import Foundation

/// Describes a sphere identity and petname at a specific version
struct SphereSnapshot: Hashable, Codable {
    /// DID of sphere
    var identity: Did
    /// Sphere version
    var version: Cid
    /// Petname assigned to sphere (if any).
    /// In practical use, we often use `nil` to mean "our sphere"
    var petname: Petname?
}
