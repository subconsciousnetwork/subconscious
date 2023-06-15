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
    var user: UserProfile
    var statistics: UserProfileStatistics?

    var description: String {
        """
        \(String(describing: user.nickname))
        Following? \(user.isFollowedByUs)
        
        \(user.bio)
        """
    }
}
