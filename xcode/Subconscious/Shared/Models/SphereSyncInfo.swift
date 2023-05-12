//
//  SphereSyncInfoRecord.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/12/23.
//

import Foundation

/// Model for databasesphere sync info
struct SphereSyncInfo: Hashable, Codable {
    var identity: Did
    var version: Cid
    var petname: Petname?
}
