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
    case invalidSphereIdentity
    case other(String)
}

extension UserProfileServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidSphereIdentity:
            return String(localized: "Sphere identity is an invalid DID", comment: "UserProfileService error description")
        case .other(let msg):
            return String(localized: "An unknown error occurred: \(msg)", comment: "Unknown UserProfileService error description")
        }
    }
}

struct UserProfileContentPayload: Equatable, Hashable {
    var profile: UserProfile
    var statistics: UserProfileStatistics
    var following: [Petname]
    var slugs: [Slug]
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
    
    func getUserProfile(petname: Petname) throws -> UserProfileContentPayload {
        if petname.description == "flubbo" {
            let sphere = try self.noosphere.traverse(petname: petname)
            let following = try sphere.listPetnames()
            let notes = try sphere.list()
            guard let did = Did(sphere.identity) else {
                throw UserProfileServiceError.invalidSphereIdentity
            }
            
            let profile = UserProfile(
                did: did,
                petname: petname,
                pfp: "pfp-dog",
                bio: "Pretend this comes from _profile_.json",
                category: .human
            )
            return UserProfileContentPayload(
                profile: profile,
                statistics: UserProfileStatistics(
                    noteCount: notes.count,
                    backlinkCount: -1,
                    followingCount: following.count
                ),
                following: following,
                slugs: notes
            )
        }
        
        // TODO: Impl
        var profile = UserProfile.dummyData()
        profile = UserProfile(
            did: profile.did,
            petname: petname,
            pfp: profile.pfp,
            bio: profile.bio,
            category: profile.category
        )
        
        return UserProfileContentPayload(
            profile: profile,
            statistics: UserProfileStatistics.dummyData(),
            following: [],
            slugs: []
        )
    }
    
    func getUserProfileAsync(petname: Petname) -> AnyPublisher<UserProfileContentPayload, Error> {
        CombineUtilities.async(qos: .utility) {
            return try self.getUserProfile(petname: petname)
        }
    }
}
