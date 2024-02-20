//
//  NeighborRecord.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 16/2/2024.
//

import Foundation

struct NeighborRecord: Hashable, Identifiable {
    var id: String { identity.description }
    
    var petname: Petname
    var identity: Did
    var address: Slashlink
    var nickname: Petname.Name?
    var bio: UserProfileBio?
    var peer: Petname
    var since: Cid?
}

