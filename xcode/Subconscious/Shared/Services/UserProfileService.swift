//
//  UserProfileService.swift
//  Subconscious
//
//  Created by Ben Follington on 13/4/2023.
//

import Foundation
import Combine
// temp
import SwiftUI

enum UserProfileServiceError: Error {
    case other(String)
}

extension UserProfileServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .other(let msg):
            return String(localized: "An unknown error occurred: \(msg)", comment: "Unknown UserProfileService error description")
        }
    }
}

class UserProfileService {
    private(set) var noosphere: NoosphereService
    private(set) var database: DatabaseService
    private(set) var addressBook: AddressBookService
    
    init(noosphere: NoosphereService, database: DatabaseService, addressBook: AddressBookService) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
    }
    
    func getUserProfile(petname: Petname) -> UserProfile {
        // TODO: Impl
        var profile = UserProfile.dummyData()
        profile = UserProfile(
            did: profile.did,
            petname: petname,
            pfp: profile.pfp,
            bio: profile.bio,
            category: profile.category
        )
        
        return profile
    }
    
    func getUserProfileAsync(petname: Petname) -> AnyPublisher<UserProfile, Error> {
        CombineUtilities.async(qos: .utility) {
            return self.getUserProfile(petname: petname)
        }
    }
}
