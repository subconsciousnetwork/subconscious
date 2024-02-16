//
//  AssociateRecord.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 16/2/2024.
//

import Foundation

struct AssociateRecord: Hashable {
    var petname: Petname
    var identity: Did
    var address: Slashlink
    var peer: Petname
    var since: Cid?
}
