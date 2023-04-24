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
    case unexpectedProfileContentType(String)
    case failedToDeserializeProfile(Error, String?)
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
        case .unexpectedProfileContentType(let contentType):
            return String(
                localized: "Unexpected content type \(contentType) encountered reading profile memo",
                comment: "UserProfileService error description"
            )
        case .failedToDeserializeProfile(let error, let data):
            switch data {
            case .some(let data):
                return String(
                    localized: "Failed to deserialize string \"\(data)\": \(error.localizedDescription)",
                    comment: "UserProfileService error description"
                )
            case .none:
                return String(
                    localized: "Failed to deserialize: \(error.localizedDescription)",
                    comment: "UserProfileService error description"
                )
            }
        case .other(let msg):
            return String(
                localized: "An unknown error occurred: \(msg)",
                comment: "Unknown UserProfileService error description"
            )
        }
    }
}

struct UserProfileContentResponse: Equatable, Hashable {
    var profile: UserProfile
    var statistics: UserProfileStatistics
    var following: [StoryUser]
    var entries: [EntryStub]
    var isFollowingUser: Bool
}

struct UserProfileEntry: Codable, Equatable {
    static let currentVersion = "0.0"
    
    let version: String
    let preferredName: String?
    let bio: String?
    // TODO: should we store the pfp in a memo?
    let profilePictureUrl: String?
}

actor UserProfileService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBookService
    private var jsonDecoder: JSONDecoder
    private var jsonEncoder: JSONEncoder
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserProfileService"
    )
    
    private static let profileContentType = "application/json"
    
    init(
        noosphere: NoosphereService,
        database: DatabaseService,
        addressBook: AddressBookService
    ) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
        
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
        // ensure keys are sorted on write to maintain content hash
        self.jsonEncoder.outputFormatting = .sortedKeys
    }
    
    func writeOurProfile(profile: UserProfileEntry) async throws {
        let data = try self.jsonEncoder.encode(profile)
        
        try await self.noosphere.write(
            slug: Slug.profile,
            contentType: Self.profileContentType,
            additionalHeaders: [],
            body: data
        )
        
        _ = try await self.noosphere.sync()
    }
    
    /// Attempt to read & deserialize a user `_profile_.json` at the given address.
    /// Because profile data is optional and we expect it will not always be present
    /// any errors are logged & handled and nil will be returned if reading fails.
    func readProfile(address: MemoAddress) async -> UserProfileEntry? {
        do {
            let data = try await noosphere.read(slashlink: address.toSlashlink())
            
            guard data.contentType == Self.profileContentType else {
                throw UserProfileServiceError.unexpectedProfileContentType(data.contentType)
            }
            
            do {
                return try jsonDecoder.decode(UserProfileEntry.self, from: data.body)
            } catch {
                // catch errors so we can give more context if there was a formatting error
                guard let string = String(data: data.body, encoding: .utf8) else {
                    throw UserProfileServiceError.failedToDeserializeProfile(error, nil)
                }
               
                throw UserProfileServiceError.failedToDeserializeProfile(error, string)
            }
        } catch {
            logger.warning(
                "Failed to read profile at \(address): \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func requestOwnProfile() async throws -> UserProfileContentResponse {
        guard let nickname = AppDefaults.standard.nickname,
              let petname = Petname(nickname) else {
                  throw UserProfileServiceError.missingPreferredPetname
        }
        
        let did = try await self.noosphere.identity()
        let following = try await self.getFollowingList(
            sphere: self.noosphere,
            localAddressBook: AddressBook(sphere: self.noosphere),
            address: Slashlink.ourProfile.toPublicMemoAddress()
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
        
        let address = Slashlink.ourProfile.toPublicMemoAddress()
        let userProfileData = await readProfile(address: address)
        
        let profile = UserProfile(
            did: did,
            petname: Petname(userProfileData?.preferredName ?? "") ?? petname,
            preferredPetname: userProfileData?.preferredName,
            address: address,
            pfp: userProfileData?.profilePictureUrl ?? "sub_logo",
            bio: userProfileData?.bio ?? "",
            category: .you
        )
        
        return UserProfileContentResponse(
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
    
    nonisolated func requestOwnProfilePublisher() -> AnyPublisher<UserProfileContentResponse, Error> {
        Future.detached {
            try await self.requestOwnProfile()
        }
        .eraseToAnyPublisher()
    }
    
    /// Retrieve all the content for the passed user's profile view, fetching their profile, notes and address book.
    func requestUserProfile(petname: Petname) async throws -> UserProfileContentResponse {
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
            return try await requestOwnProfile()
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
        
        let address = Slashlink(petname: petname).toPublicMemoAddress()
        let userProfileData = await readProfile(address: address)
        
        let profile = UserProfile(
            did: did,
            petname: petname,
            preferredPetname: userProfileData?.preferredName,
            address: address,
            pfp: userProfileData?.profilePictureUrl ?? "sub_logo",
            bio: userProfileData?.bio ?? "",
            category: .human
        )
        
        return UserProfileContentResponse(
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
    
    nonisolated func requestUserProfilePublisher(
        petname: Petname
    ) -> AnyPublisher<UserProfileContentResponse, Error> {
        Future.detached {
            try await self.requestUserProfile(petname: petname)
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
            
            let address =
                isOurs
                ? Slashlink.ourProfile.toPublicMemoAddress()
                : Slashlink(petname: petname).toPublicMemoAddress()
            let userProfileData = await readProfile(address: address)
            
            let user = UserProfile(
                did: did,
                petname: petname,
                preferredPetname: userProfileData?.preferredName,
                address: address,
                pfp: userProfileData?.profilePictureUrl ?? "sub_logo",
                bio: userProfileData?.bio ?? "",
                category: isOurs ? .you : .human
            )
            
            let weAreFollowingListedUser = await self.addressBook.isFollowingUser(did: did)
            
            following.append(
                StoryUser(
                    user: user,
                    isFollowingUser: weAreFollowingListedUser
                )
            )
        }
        
        return following
    }
}
