//
//  StoryUser.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

/// Story prompt model
struct StoryUser:
    Hashable,
    Identifiable,
    CustomStringConvertible,
    Codable {
    
    var id = UUID()
    var entry: AddressBookEntry
    var user: UserProfile
    var statistics: UserProfileStatistics?

    var description: String {
        let nickname = String(describing: user.nickname)
        return "StoryUser(\(user.did), \(user.address), \(nickname), \(user.ourFollowStatus))"
    }
}
