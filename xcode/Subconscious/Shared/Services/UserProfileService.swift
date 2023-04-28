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
    var following: [StoryUser]
    var entries: [EntryStub]
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
        address: MemoAddress
    ) async -> UserProfileEntry? {
        do {
            let data = try await noosphere.read(slashlink: address.toSlashlink())
            
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
    private func loadProfile(
        did: Did,
        petname: Petname,
        address: MemoAddress
    ) async throws -> UserProfile {
        let userProfileData = await self.readProfileMemo(address: address)
        let pfp: ProfilePicVariant = Func.run {
            if let url = URL(string: userProfileData?.profilePictureUrl ?? "") {
                return .url(url)
            }
            
            return .none
        }
        
        let profile = UserProfile(
            did: did,
            nickname: Petname(userProfileData?.nickname ?? "") ?? petname,
            address: address,
            pfp: pfp,
            bio: userProfileData?.bio ?? "",
            category: address.isOurProfile ? .you : .human
        )
        
        return profile
    }
    
    /// Takes a list of slugs and prepares an `EntryStub` for each, excluding hidden slugs.
    private func loadEntries<Sphere: SphereProtocol>(
        petname: Petname?,
        slugs: [Slug],
        sphere: Sphere
    ) async throws -> [EntryStub] {
        var entries: [EntryStub] = []
        for slug in slugs {
            guard !slug.isHidden else {
                continue
            }
            
            let slashlink = Slashlink(slug: slug)
            let memo = try await sphere.read(slashlink: slashlink)
            
            guard let memo = memo.toMemo() else {
                continue
            }

            entries.append(
                EntryStub(
                    address: Slashlink(
                        petname: petname,
                        slug: slug
                    ).toPublicMemoAddress(),
                    excerpt: memo.excerpt(),
                    modified: memo.modified
                )
            )
        }
        
        return entries
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
            guard let did = try await localAddressBook.getPetname(
                petname: petname
            ) else {
                continue
            }
            
            let petname = address.petname?.append(petname: petname) ?? petname
            let noosphereIdentity = try await noosphere.identity()
            let isOurs = noosphereIdentity.id == did.id
            
            let address =
                isOurs
                ? Slashlink.ourProfile.toPublicMemoAddress()
                : Slashlink(petname: petname).toPublicMemoAddress()
            
            let user = try await self.loadProfile(
                did: did,
                petname: petname,
                address: address
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
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func requestOurProfile() async throws -> UserProfileContentResponse {
        guard let nickname = AppDefaults.standard.nickname,
              let nickname = Petname(nickname) else {
                  throw UserProfileServiceError.missingPreferredPetname
        }
        
        let address = Slashlink.ourProfile.toPublicMemoAddress()
        let did = try await self.noosphere.identity()
        let following = try await self.getFollowingList(
            sphere: self.noosphere,
            localAddressBook: AddressBook(sphere: self.noosphere),
            address: address
        )
        let notes = try await self.noosphere.list()
        let entries = try await self.loadEntries(
            petname: nil,
            slugs: notes,
            sphere: self.noosphere
        )
        
        let profile = try await self.loadProfile(
            did: did,
            petname: nickname,
            address: address
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
        let address = Slashlink(petname: petname).toPublicMemoAddress()
        
        let sphere = try await self.noosphere.traverse(petname: petname)
        let identity = try await sphere.identity()
        let localAddressBook = AddressBook(sphere: sphere)
        let following: [StoryUser] = try await self.getFollowingList(
            sphere: sphere,
            localAddressBook: localAddressBook,
            address: address
        )
        
        // Detect your own profile and intercept
        guard try await self.noosphere.identity() != identity else {
            return try await requestOurProfile()
        }
        
        let notes = try await sphere.list()
        let isFollowing = await self.addressBook.isFollowingUser(did: identity)
        let entries = try await self.loadEntries(
            petname: petname,
            slugs: notes,
            sphere: sphere
        )
        
        let profile = try await self.loadProfile(
            did: identity,
            petname: petname,
            address: address
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
   
}
