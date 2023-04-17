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

class UserProfileService {
    private(set) var noosphere: NoosphereService
    private(set) var database: DatabaseService
    private(set) var addressBook: AddressBookService<NoosphereService>
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileService"
    )
    
    init(noosphere: NoosphereService, database: DatabaseService, addressBook: AddressBookService<NoosphereService>) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
    }
    
    private func isFollowing(noosphere: NoosphereService, did: Did) -> Bool {
        // TODO: Replace with isFollowingUser with DID check once that PR lands
        do {
            return try noosphere.listPetnames()
                .contains(where: { f in
                    guard let followingDid = try self.addressBook.addressBook.getPetname(petname: f) else {
                        return false
                    }
                    
                    return did == followingDid
                })
        } catch {
            logger.warning("Failed to check following status, temporary issue.")
            return false
        }
    }
    
    func getOwnProfile() throws -> UserProfileContentPayload {
        let did = try self.noosphere.identity()
        let petname = Petname("___")!
        let sphere = try self.noosphere.sphere()
        let following = try self.produceFollowingList(sphere: sphere, localAddressBook: AddressBook(sphere: sphere), basePath: [])
        let notes = try self.noosphere.list()
        
        let entries: [EntryStub] = try notes.compactMap { slug in
            let slashlink = Slashlink(slug: slug)
            let memo = try noosphere.read(slashlink: slashlink)
            
            guard let memo = memo.toMemo() else {
                return nil
            }

            return EntryStub(
                address: Slashlink(petname: petname, slug: slug).toPublicMemoAddress(),
                excerpt: memo.excerpt(),
                modified: memo.modified
            )
        }
        
        guard let did = Did(did) else {
            throw UserProfileServiceError.invalidSphereIdentity
        }
        
        let profile = UserProfile(
            did: did,
            petname: petname,
            pfp: "sub_logo",
            bio: "Wow, it's your own profile! With its own codepath!",
            category: .you
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
            isFollowingUser: false
        )
    }
    
    func getOwnProfileAsync() -> AnyPublisher<UserProfileContentPayload, Error> {
        CombineUtilities.async(qos: .default) {
            return try self.getOwnProfile()
        }
    }
    
    private func produceFollowingList<Sphere: SphereProtocol>(sphere: Sphere, localAddressBook: AddressBook<Sphere>, basePath: SpherePath) throws -> [StoryUser] {
        return try sphere.listPetnames()
            .compactMap { f -> StoryUser? in
                guard let did = try localAddressBook.getPetname(petname: f) else {
                    return nil
                }
                
                guard let petname = Petname(petnames: [f] + basePath) else {
                    return nil
                }
                
                let noosphereIdentity = try noosphere.identity()
                
                let user = UserProfile(
                    did: did,
                    petname: petname,
                    pfp: String.dummyProfilePicture(),
                    bio: String.dummyDataMedium(),
                    category: noosphereIdentity == did.did ? .you : .human
                )
                
                let following =
                    try addressBook.addressBook.listPetnames()
                    .map { p in
                        try addressBook.addressBook.getPetname(petname: p)
                    }
                    .contains(where: { followedDid in
                        followedDid == did
                    })
                
                return StoryUser(user: user, isFollowingUser: following)
            }
    }
    
    func getUserProfile(petname: Petname) throws -> UserProfileContentPayload {
        let sphere = try self.noosphere.traverse(petname: petname)
        let identity = try sphere.identity()
        let localAddressBook = AddressBook(sphere: sphere)
        let basePath = [petname]
        let following: [StoryUser] = try self.produceFollowingList(sphere: sphere, localAddressBook: localAddressBook, basePath: basePath)
        
        // Detect your own profile and intercept
        guard try self.noosphere.identity() != identity else {
            return try getOwnProfile()
        }
        
        guard let did = Did(identity) else {
            throw UserProfileServiceError.invalidSphereIdentity
        }
        
        let notes = try sphere.list()
        
        let isFollowing = isFollowing(noosphere: self.noosphere, did: did)
        
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
    
    func getUserProfileAsync(petname: Petname) -> AnyPublisher<UserProfileContentPayload, Error> {
        CombineUtilities.async(qos: .default) {
            return try self.getUserProfile(petname: petname)
        }
    }
}
