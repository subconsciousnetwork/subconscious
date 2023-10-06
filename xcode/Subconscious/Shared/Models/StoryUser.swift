//
//  StoryUser.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

enum StoryUserVariant: Codable, Equatable, Hashable {
    case unknown(AddressBookEntry)
    case known(UserProfile, AddressBookEntry)
}

extension StoryUserVariant {
    var entry: AddressBookEntry {
        switch self {
        case .unknown(let entry):
            return entry
        case .known(_, let entry):
            return entry
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
    
    var entry: AddressBookEntry {
        switch user {
        case .unknown(let entry):
            return entry
        case .known(_, let entry):
            return entry
        }
    }

    var description: String {
        """
        \(String(describing: entry.did))
        \(String(describing: entry.petname))
        \(String(describing: entry.status))
        """
    }
}
