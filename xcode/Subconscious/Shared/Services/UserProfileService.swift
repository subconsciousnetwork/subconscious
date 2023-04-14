//
//  UserProfileService.swift
//  Subconscious
//
//  Created by Ben Follington on 13/4/2023.
//

import os
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
    var following: [StoryUser]
    var entries: [EntryStub]
    var isFollowingUser: Bool
}

class UserProfileService<Sphere : SphereProtocol> {
    private(set) var sphere: Sphere
    private(set) var database: DatabaseService
    private(set) var addressBook: AddressBookService<Sphere>
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileService"
    )
    
    init(sphere: Sphere, database: DatabaseService, addressBook: AddressBookService<Sphere>) {
        self.sphere = sphere
        self.database = database
        self.addressBook = addressBook
    }
    
    private func isFollowing(sphere: Sphere, petname: Petname) -> Bool {
        // TODO: Replace with isFollowingUser with DID check once that PR lands
        do {
            return try self.addressBook.getPetname(petname: petname) != nil
        } catch {
            logger.warning("Failed to check following status, temporary issue.")
            return false
        }
    }
    
    func getUserProfile(did: Did, petname: Petname) throws -> UserProfileContentPayload {
        let sphere = try self.sphere.traverse(did: did, petname: petname)
        let localAddressBook = AddressBookService(sphere: sphere, database: database)
        let following: [StoryUser] =
            try sphere.listPetnames()
            .compactMap { f in
                guard let did = try localAddressBook.getPetname(petname: f) else {
                    return nil
                }
                
                guard let petname = Petname(petnames: [f, petname]) else {
                    return nil
                }
                
                let user = UserProfile(
                    did: did,
                    petname: petname,
                    pfp: String.dummyProfilePicture(),
                    bio: String.dummyDataMedium(),
                    category: .human
                )
                
                let following =
                    try addressBook.listPetnames()
                    .map { p in
                        try addressBook.getPetname(petname: p)
                    }
                    .contains(where: { followedDid in
                        followedDid == did
                    })
                
                return StoryUser(user: user, isFollowingUser: following)
            }
        
        let notes = try sphere.list()
        guard let did = Did(try sphere.identity()) else {
            throw UserProfileServiceError.invalidSphereIdentity
        }
        
        let isFollowing = isFollowing(sphere: self.sphere, petname: petname)
        
        let entries: [EntryStub] = try notes.compactMap { slug in
            let slashlink = Slashlink(slug: slug)
            let memo = try sphere.read(slashlink: slashlink)
            guard let memo = memo.toMemo() else {
                return nil
            }
            
            return EntryStub(
                address: Slashlink(petname: petname, slug: slug).toPublicMemoAddress(),
                excerpt: memo.excerpt(),
                modified: memo.modified
            )
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
                noteCount: entries.count,
                backlinkCount: -1,
                followingCount: following.count
            ),
            following: following,
            entries: entries,
            isFollowingUser: isFollowing
        )
    }
    
    func getUserProfileAsync(did: Did, petname: Petname) -> AnyPublisher<UserProfileContentPayload, Error> {
        CombineUtilities.async(qos: .utility) {
            return try self.getUserProfile(did: did, petname: petname)
        }
    }
}
