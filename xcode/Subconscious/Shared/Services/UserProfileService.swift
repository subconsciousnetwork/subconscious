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
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBookService
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileService"
    )
    
    init(noosphere: NoosphereService, database: DatabaseService, addressBook: AddressBookService) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
    }
    
    func getOwnProfile() async throws -> UserProfileContentPayload {
        let did = try await self.noosphere.identity()
        let petname = Petname(AppDefaults.standard.nickname ?? "???")!
        let sphere = try await self.noosphere.sphere()
        let following = try await self.produceFollowingList(sphere: sphere, localAddressBook: AddressBook(sphere: sphere), basePath: [])
        let notes = try await self.noosphere.list()
        
        var entries: [EntryStub] = []
        
        for slug in notes {
            let slashlink = Slashlink(slug: slug)
            let memo = try await noosphere.read(slashlink: slashlink)
            
            guard let memo = memo.toMemo() else {
                continue
            }

            entries.append(
                EntryStub(
                    address: Slashlink(petname: petname, slug: slug).toPublicMemoAddress(),
                    excerpt: memo.excerpt(),
                    modified: memo.modified
                )
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
    
    func getOwnProfilePublisher() -> AnyPublisher<UserProfileContentPayload, Error> {
        Future.detached {
            return try await self.getOwnProfile()
        }
        .eraseToAnyPublisher()
    }
    
    private func produceFollowingList<Sphere: SphereProtocol>(sphere: Sphere, localAddressBook: AddressBook<Sphere>, basePath: SpherePath) async throws -> [StoryUser] {
        var following: [StoryUser] = []
        let petnames = try await sphere.listPetnames()
        for petname in petnames {
            guard let did = try await localAddressBook.getPetname(petname: petname) else {
                continue
            }
            
            guard let petname = Petname(petnames: [petname] + basePath) else {
                continue
            }
            
            let noosphereIdentity = try await noosphere.identity()
            
            let user = UserProfile(
                did: did,
                petname: petname,
                pfp: String.dummyProfilePicture(),
                bio: String.dummyDataMedium(),
                category: noosphereIdentity == did.did ? .you : .human
            )
            
            let isFollowingUser = await self.addressBook.isFollowingUser(did: did)
            
            following.append(
                StoryUser(
                    user: user,
                    isFollowingUser: isFollowingUser
                )
            )
        }
        
        return following
    }
    
    func getUserProfile(petname: Petname) async throws -> UserProfileContentPayload {
        let sphere = try await self.noosphere.traverse(petname: petname)
        let identity = try await sphere.identity()
        let localAddressBook = AddressBook(sphere: sphere)
        let basePath = [petname]
        let following: [StoryUser] = try await self.produceFollowingList(sphere: sphere, localAddressBook: localAddressBook, basePath: basePath)
        
        // Detect your own profile and intercept
        guard try await self.noosphere.identity() != identity else {
            return try await getOwnProfile()
        }
        
        guard let did = Did(identity) else {
            throw UserProfileServiceError.invalidSphereIdentity
        }
        
        let notes = try await sphere.list()
        let isFollowing = await self.addressBook.isFollowingUser(did: did)
        
        var entries: [EntryStub] = []
        
        for slug in notes {
            let slashlink = Slashlink(slug: slug)
            let memo = try await sphere.read(slashlink: slashlink)
            
            guard let memo = memo.toMemo() else {
                continue
            }

            entries.append(
                EntryStub(
                    address: Slashlink(petname: petname, slug: slug).toPublicMemoAddress(),
                    excerpt: memo.excerpt(),
                    modified: memo.modified
                )
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
    
    func getUserProfilePublisher(petname: Petname) -> AnyPublisher<UserProfileContentPayload, Error> {
        Future.detached {
            return try await self.getUserProfile(petname: petname)
        }
        .eraseToAnyPublisher()
    }
}
