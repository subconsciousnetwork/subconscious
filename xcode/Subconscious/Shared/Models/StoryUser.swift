//
//  StoryUser.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

enum StoryUserVariant: Codable, Equatable, Hashable {
    case unknown(Slashlink, AddressBookEntry)
    case known(UserProfile, AddressBookEntry)
}

extension StoryUserVariant {
    var entry: AddressBookEntry {
        switch self {
        case .unknown(_, let entry):
            return entry
        case .known(_, let entry):
            return entry
        }
    }
    
    var address: Slashlink {
        switch self {
        case .unknown(let address, _):
            return address
        case .known(let user, _):
            return user.address
        }
    }
}

/// Story prompt model
struct StoryUser:
    Hashable,
    Identifiable,
    CustomStringConvertible,
    Codable {
    
    var id = UUID()
    var user: StoryUserVariant
    var statistics: UserProfileStatistics?

    var description: String {
        """
        \(String(describing: user.address))
        \(String(describing: user.entry.did))
        \(String(describing: user.entry.petname))
        \(String(describing: user.entry.status))
        """
    }
}
