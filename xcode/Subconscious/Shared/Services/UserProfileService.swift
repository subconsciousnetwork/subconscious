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
    case missingPreferredPetname
    case unexpectedProfileContentType(String)
    case unexpectedProfileSchemaVersion(String)
    case failedToDeserializeProfile(Error, String?)
    case other(String)
}

extension UserProfileServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingPreferredPetname:
            return String(
                localized: "Missing or invalid nickname for sphere owner",
                comment: "UserProfileService error description"
            )
        case .unexpectedProfileContentType(let contentType):
            return String(
                localized: "Unexpected content type \(contentType) found reading profile memo",
                comment: "UserProfileService error description"
            )
        case .unexpectedProfileSchemaVersion(let versionString):
            return String(
                localized: "Unexpected version string \"\(versionString)\" found reading profile",
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
    var recentEntries: [EntryStub]
    var following: [StoryUser]
    var isFollowingUser: Bool
}

struct UserProfileEntry: Codable, Equatable {
    static let currentVersion = "0.0"
    
    init(nickname: String?, bio: String?, profilePictureUrl: String?) {
        self.version = Self.currentVersion
        self.nickname = nickname
        self.bio = bio
        self.profilePictureUrl = profilePictureUrl
    }
    
    let version: String
    let nickname: String?
    let bio: String?
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
    
    private static let profileContentType = "application/vnd.subconscious.profile+json"
    
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
    
    
    /// Attempt to read & deserialize a user `_profile_.json` at the given address.
    /// Because profile data is optional and we expect it will not always be present
    /// any errors are logged & handled and nil will be returned if reading fails.
    private func readProfileMemo(
        address: Slashlink
    ) async -> UserProfileEntry? {
        do {
            let data = try await noosphere.read(slashlink: address)
            
            guard data.contentType == Self.profileContentType else {
                throw UserProfileServiceError.unexpectedProfileContentType(data.contentType)
            }
            
            do {
                let profile = try jsonDecoder.decode(UserProfileEntry.self, from: data.body)
                
                guard profile.version == UserProfileEntry.currentVersion else {
                    throw UserProfileServiceError.unexpectedProfileSchemaVersion(profile.version)
                }
                
                return profile
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
    
    /// Load the underlying `_profile_` for a user and construct a `UserProfile` from it.
    private func loadProfileFromMemo(
        did: Did,
        fallbackPetname: Petname,
        address: Slashlink
    ) async throws -> UserProfile {
        let userProfileData = await self.readProfileMemo(address: address)
        let pfp: ProfilePicVariant = Func.run {
            if let url = URL(string: userProfileData?.profilePictureUrl ?? "") {
                return .url(url)
            }
            
            return .none(did)
        }
        
        let profile = UserProfile(
            did: did,
            nickname: Petname(userProfileData?.nickname ?? "") ?? fallbackPetname,
            address: address,
            pfp: pfp,
            bio: userProfileData?.bio ?? "",
            category: address.isOurProfile ? .you : .human
        )
        
        return profile
    }
    
    /// Takes a list of slugs and prepares an `EntryStub` for each, excluding hidden slugs.
    private func loadEntries(
        address: Slashlink,
        slugs: [Slug]
    ) async throws -> [EntryStub] {
        var entries: [EntryStub] = []
        for slug in slugs {
            guard !slug.isHidden else {
                continue
            }
            
            let sphere = try await self.noosphere.sphere(address: address)
            let slashlink = Slashlink(slug: slug)
            let memo = try await sphere.read(slashlink: slashlink)
            
            guard let memo = memo.toMemo() else {
                continue
            }

            entries.append(
                EntryStub(
                    address: Slashlink(
                        petname: address.petname,
                        slug: slug
                    ),
                    excerpt: memo.excerpt(),
                    modified: memo.modified
                )
            )
        }
        
        return entries
    }
    
    /// Produce a reverse-chronological list of the entries passed in
    private func recentEntries(entries: [EntryStub]) -> [EntryStub] {
        var recentEntries = entries
        recentEntries.sort(by: { a, b in
            a.modified > b.modified
        })
        
        return recentEntries
    }

    /// List all the users followed by the passed sphere.
    /// Each user will be decorated with whether the current app user is following them.
    func getFollowingList(
        address: Slashlink
    ) async throws -> [StoryUser] {
        var following: [StoryUser] = []
        let sphere = try await self.noosphere.sphere(address: address)
        
        let localAddressBook = AddressBook(sphere: sphere)
        
        let entries = try await localAddressBook.listEntries(refetch: true)
        
        for entry in entries {
            let noosphereIdentity = try await noosphere.identity()
            let isOurs = noosphereIdentity == entry.did
            
            let slashlink = Func.run {
                guard case let .petname(basePetname) = address.peer else {
                    return Slashlink(petname: entry.petname)
                }
                return Slashlink(petname: entry.petname).rebaseIfNeeded(petname: basePetname)
            }
            
            let address = isOurs
                ? Slashlink.ourProfile
                : slashlink
            
            let user = try await self.loadProfileFromMemo(
                did: entry.did,
                fallbackPetname: address.petname ?? entry.petname,
                address: address
            )
            
            let weAreFollowingListedUser = await self.addressBook.isFollowingUser(did: entry.did)
            
            following.append(
                StoryUser(
                    user: user,
                    isFollowingUser: weAreFollowingListedUser
                )
            )
        }
        
        return following
    }
    
    /// Update our `_profile_` memo with the contents of the passed profile.
    /// This will save the underlying sphere and attempt to sync.
    func writeOurProfile(profile: UserProfileEntry) async throws {
        let data = try self.jsonEncoder.encode(profile)
        
        try await self.noosphere.write(
            slug: Slug.profile,
            contentType: Self.profileContentType,
            additionalHeaders: [],
            body: data
        )
        
        let _ = try await self.noosphere.save()
        
        do {
            _ = try await self.noosphere.sync()
        } catch {
            // Swallow this error in the event syncing fails
            // Editing the profile still succeeded
            logger.warning("Failed to sync after updating profile: \(error.localizedDescription)")
        }
    }
    
    func loadProfileData(
        address: Slashlink,
        fallbackPetname: Petname
    ) async throws -> UserProfileContentResponse {
        let sphere = try await self.noosphere.sphere(address: address)
        let did = try await sphere.identity()
        
        let following = try await self.getFollowingList(
            address: address
        )
        let notes = try await sphere.list()
        let isFollowing = await self.addressBook.isFollowingUser(did: did)
        
        let entries = try await self.loadEntries(
            address: address,
            slugs: notes
        )
        let topEntries = entries
        let recentEntries = recentEntries(entries: entries)
        
        let profile = try await self.loadProfileFromMemo(
            did: did,
            fallbackPetname: fallbackPetname,
            address: address
        )
        
        return UserProfileContentResponse(
            profile: profile,
            statistics: UserProfileStatistics(
                noteCount: entries.count,
                backlinkCount: -1, // TODO: populate with real count
                followingCount: following.count
            ),
            recentEntries: recentEntries,
            following: following,
            isFollowingUser: isFollowing
        )
    }
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func requestOurProfile() async throws -> UserProfileContentResponse {
        guard let nickname = AppDefaults.standard.nickname,
              let nickname = Petname(nickname) else {
                  throw UserProfileServiceError.missingPreferredPetname
        }
        
        let address = Slashlink.ourProfile
        return try await loadProfileData(address: address, fallbackPetname: nickname)
    }
    
    nonisolated func requestOwnProfilePublisher(
    ) -> AnyPublisher<UserProfileContentResponse, Error> {
        Future.detached {
            try await self.requestOurProfile()
        }
        .eraseToAnyPublisher()
    }
    
    /// Retrieve all the content for the passed user's profile view, fetching their profile, notes and address book.
    func requestUserProfile(
        petname: Petname
    ) async throws -> UserProfileContentResponse {
        let address = Slashlink(petname: petname)
        return try await loadProfileData(address: address, fallbackPetname: petname)
    }
    
    nonisolated func requestUserProfilePublisher(
        petname: Petname
    ) -> AnyPublisher<UserProfileContentResponse, Error> {
        Future.detached {
            try await self.requestUserProfile(petname: petname)
        }
        .eraseToAnyPublisher()
    }
   
}
