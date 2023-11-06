//
//  Address.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation

struct ResolvedAddress: Equatable, Hashable {
    var owner: Did
    var slashlink: Slashlink
}
