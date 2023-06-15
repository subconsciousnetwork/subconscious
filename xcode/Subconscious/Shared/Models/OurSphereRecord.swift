//
//  OurSphereRecord.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/16/23.
//

import Foundation

struct OurSphereRecord: Hashable, Codable {
    /// Sphere identity
    var identity: Did
    /// Last indexed sphere version
    var since: Cid
}
