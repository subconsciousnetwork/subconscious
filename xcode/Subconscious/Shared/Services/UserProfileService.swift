//
//  UserProfileService.swift
//  Subconscious
//
//  Created by Ben Follington on 13/4/2023.
//

import os
import Foundation
import Combine

enum UserProfileServiceError: Error {
    case invalidSphereIdentity
    case missingPreferredPetname
    case other(String)
}

extension UserProfileServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidSphereIdentity:
            return String(
                localized: "Sphere identity is an invalid DID",
                comment: "UserProfileService error description"
            )
        case .missingPreferredPetname:
            return String(
                localized: "Missing or invalid nickname for sphere owner",
                comment: "UserProfileService error description"
            )
        case .other(let msg):
            return String(
                localized: "An unknown error occurred: \(msg)",
                comment: "Unknown UserProfileService error description"
            )
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

actor UserProfileService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBookService
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileService"
    )
    
    init(
        noosphere: NoosphereService,
        database: DatabaseService,
        addressBook: AddressBookService
    ) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
    }
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func getOwnProfile() async throws -> UserProfileContentPayload {
        guard let nickname = AppDefaults.standard.nickname,
              let petname = Petname(nickname) else {
                  throw UserProfileServiceError.missingPreferredPetname
        }
        
        let did = try await self.noosphere.identity()
        let following = try await self.getFollowingList(
            sphere: self.noosphere,
            localAddressBook: AddressBook(sphere: self.noosphere),
            address: Slashlink.ourProfile.toLocalMemoAddress()
        )
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
                    address: Slashlink(slug: slug).toPublicMemoAddress(),
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
            address: Slashlink.ourProfile.toLocalMemoAddress(),
            // TODO: replace with _profile_.json data
            pfp: "sub_logo",
            bio: "Wow, it's your own profile! With its own codepath!",
            category: .you
        )
        
        return UserProfileContentPayload(
            profile: profile,
            statistics: UserProfileStatistics(
                noteCount: entries.count,
                backlinkCount: -1, // TODO: populate with real count
                followingCount: following.count
            ),
            following: following,
            entries: entries,
            isFollowingUser: false
        )
    }
    
    nonisolated func getOwnProfilePublisher() -> AnyPublisher<UserProfileContentPayload, Error> {
        Future.detached {
            return try await self.getOwnProfile()
        }
        .eraseToAnyPublisher()
    }
    
    /// Retrieve all the content for the passed user's profile view, fetching their profile, notes and address book.
    func getUserProfile(petname: Petname) async throws -> UserProfileContentPayload {
        let sphere = try await self.noosphere.traverse(petname: petname)
        let identity = try await sphere.identity()
        let localAddressBook = AddressBook(sphere: sphere)
        let following: [StoryUser] = try await self.getFollowingList(
            sphere: sphere,
            localAddressBook: localAddressBook,
            address: Slashlink(petname: petname).toPublicMemoAddress()
        )
        
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
            address: Slashlink(petname: petname).toPublicMemoAddress(),
            // TODO: replace with _profile_.json data
            pfp: "pfp-dog",
            bio: "Pretend this comes from _profile_.json",
            category: .human
        )
        
        return UserProfileContentPayload(
            profile: profile,
            statistics: UserProfileStatistics(
                noteCount: entries.count,
                backlinkCount: -1, // TODO: populate with real count
                followingCount: following.count
            ),
            following: following,
            entries: entries,
            isFollowingUser: isFollowing
        )
    }
    
    nonisolated func getUserProfilePublisher(
        petname: Petname
    ) -> AnyPublisher<UserProfileContentPayload, Error> {
        Future.detached {
            return try await self.getUserProfile(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// List all the users followed by the passed sphere.
    /// Each user will be decorated with whether the current app user is following them.
    private func getFollowingList<Sphere: SphereProtocol>(
        sphere: Sphere,
        localAddressBook: AddressBook<Sphere>,
        address: MemoAddress
    ) async throws -> [StoryUser] {
        var following: [StoryUser] = []
        let petnames = try await sphere.listPetnames()
        for petname in petnames {
            guard let did = try await localAddressBook.getPetname(petname: petname) else {
                continue
            }
            
            let petname = address.petname?.append(petname: petname) ?? petname
            let noosphereIdentity = try await noosphere.identity()
            let isOurs = noosphereIdentity == did.did
            
            let user = UserProfile(
                did: did,
                petname: petname,
                address:
                    isOurs
                    ? Slashlink.ourProfile.toLocalMemoAddress()
                    : Slashlink(petname: petname).toPublicMemoAddress(),
                // TODO: replace with _profile_.json data
                pfp: String.dummyProfilePicture(),
                bio: String.dummyDataMedium(),
                category: isOurs ? .you : .human
            )
            
            let appUserIsFollowingListedUser = await self.addressBook.isFollowingUser(did: did)
            
            following.append(
                StoryUser(
                    user: user,
                    isFollowingUser: appUserIsFollowingListedUser
                )
            )
        }
        
        return following
    }
}
