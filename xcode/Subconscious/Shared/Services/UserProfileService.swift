//
//  UserProfileService.swift
//  Subconscious
//
//  Created by Ben Follington on 13/4/2023.
//

import os
import Foundation
import Combine

enum UserProfileFollowStatus: Codable, Hashable, Equatable {
    case notFollowing
    case following(Petname.Name)
}

extension UserProfileFollowStatus {
    var isFollowing: Bool {
        switch self {
        case .following(_):
            return true
        case _:
            return false
        }
    }
}

enum UserProfileServiceError: Error {
    case missingPreferredPetname
    case unexpectedProfileContentType(String)
    case unexpectedProfileSchemaVersion(String)
    case failedToDeserializeProfile(Error, String?)
    case other(String)
    case profileAlreadyExists
    case couldNotLoadSphereForProfile
    case unreachablePeer(Slashlink)
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
        case .profileAlreadyExists:
            return String(
                localized: "Request to create initial profile but user already has a profile memo",
                comment: "UserProfileService error description"
            )
        case .other(let msg):
            return String(
                localized: "An unknown error occurred: \(msg)",
                comment: "Unknown UserProfileService error description"
            )
        case .couldNotLoadSphereForProfile:
            return String(
                localized: "Failed to find or construct a sphere",
                comment: "UserProfileService error description"
            )
        case .unreachablePeer(let address):
            return String(
                localized: "Cannot reach peer at \(address.markup)",
                comment: "UserProfileService error description"
            )
        }
    }
}

struct UserProfileContentResponse: Equatable, Hashable {
    var profile: UserProfile
    var statistics: UserProfileStatistics
    var recentEntries: [EntryStub]
    var following: [StoryUser]
    var followingStatus: UserProfileFollowStatus
}

struct UserProfileEntry: Codable, Equatable {
    static let currentVersion = "0.0"
    
    init(nickname: String?, bio: String?) {
        self.version = Self.currentVersion
        self.nickname = nickname
        self.bio = UserProfileBio(bio ?? "").text
    }
    
    let version: String
    let nickname: String?
    let bio: String?
}

struct UserProfileCacheEntry {
    let profile: UserProfile
    let version: Cid
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
    
    private var cache: [Did:UserProfileCacheEntry] = [:]
    
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
            
            return try await parseProfile(body: data.body)
        } catch {
            logger.warning(
                "Failed to read profile at \(address): \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    private func readProfileFromDb(
        address: Slashlink
    ) async throws -> UserProfileEntry? {
        guard let data = try database.loadUserProfile(address: address) else {
            return nil
        }
        
        return try await parseProfile(body: data)
    }
    
    
    public func parseProfile(
        body: Data
    ) async throws -> UserProfileEntry {
        do {
            let profile = try jsonDecoder.decode(UserProfileEntry.self, from: body)
            
            guard profile.version == UserProfileEntry.currentVersion else {
                throw UserProfileServiceError.unexpectedProfileSchemaVersion(profile.version)
            }
            
            return profile
        } catch {
            // catch errors so we can give more context if there was a formatting error
            guard let string = String(data: body, encoding: .utf8) else {
                throw UserProfileServiceError.failedToDeserializeProfile(error, nil)
            }

            throw UserProfileServiceError.failedToDeserializeProfile(error, string)
        }
    }
    
    /// Load the underlying `_profile_` for a user and construct a `UserProfile` from it.
    private func loadProfileFromMemo(
        did: Did,
        address: Slashlink
    ) async throws -> UserProfile {
        let noosphereIdentity = try await noosphere.identity()
        let isOurs = noosphereIdentity == did
        
        let userProfileData = await self.readProfileMemo(
            address: isOurs ? Slashlink.ourProfile : address
        )
        
        let followingStatus = await self.addressBook.followingStatus(
            did: did,
            expectedName: address.petname?.leaf
        )
        
        let aliases = try await self.addressBook.listAliases(did: did)
        
        let profile = UserProfile(
            did: did,
            nickname: Petname.Name(userProfileData?.nickname ?? ""),
            address: address,
            pfp: .generated(did),
            bio: UserProfileBio(userProfileData?.bio ?? ""),
            category: isOurs ? UserCategory.ourself : UserCategory.human,
            ourFollowStatus: followingStatus,
            aliases: aliases
        )
        
        return profile
    }
    
    /// Takes a list of slugs and prepares an `EntryStub` for each, excluding hidden slugs.
    private func loadEntries(
        address: Slashlink,
        slugs: [Slug]
    ) async throws -> [EntryStub] {
        let sphere = try await self.noosphere.sphere(address: address)
        let identity = try await sphere.identity()
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
                    did: identity,
                    address: Slashlink(
                        petname: address.petname,
                        slug: slug
                    ),
                    excerpt: memo.excerpt(),
                    modified: memo.modified,
                    author: nil
                )
            )
        }
        
        return entries
    }
    
    /// Produce a reverse-chronological list of the entries passed in
    private func sortEntriesByModified(entries: [EntryStub]) -> [EntryStub] {
        var recentEntries = entries
        recentEntries.sort(by: { a, b in
            a.modified > b.modified
        })
        
        return recentEntries
    }

    /// List all the users followed by the passed sphere.
    /// Each user will be decorated with whether the current app user is following them.
    private func getFollowingList(
        address: Slashlink,
        sphere: Sphere
    ) async throws -> [StoryUser] {
        var following: [StoryUser] = []
        let localAddressBook = AddressBook(sphere: sphere)
        let entries = try await localAddressBook.listEntries()
        
        for entry in entries {
//            let slashlink = Func.run {
//                guard case let .petname(basePetname) = address.peer else {
//                    return Slashlink(petname: entry.name.toPetname())
//                }
//                return Slashlink(petname: entry.name.toPetname()).rebaseIfNeeded(petname: basePetname)
//            }
            
//            let resolutionStatus = try await Func.run {
//                switch (entry.status, slashlink.peer) {
//                case (.resolved(_), _):
//                    return entry.status
//                case (_, .petname(let petname)):
//                    return try await self.addressBook.resolutionStatus(petname: petname)
//                case _:
//                    return entry.status
//                }
//            }
            
            let user = try await self.identifyUser(entry: entry, context: address.peer)
            following.append(
                StoryUser(entry: entry, user: user)
            )
        }
        
        return following
    }
    
    /// Sets our nickname, preserving existing profile data.
    /// This is intended to be idempotent for use in the onboarding flow.
    func updateOurNickname(nickname: Petname.Name) async throws {
        guard let profile = await readProfileMemo(address: Slashlink.ourProfile) else {
            let profile = UserProfileEntry(
                nickname: nickname.verbatim,
                bio: nil
            )
            
            return try await writeOurProfile(profile: profile)
        }
        
        let updated = UserProfileEntry(
            nickname: nickname.verbatim,
            bio: profile.bio
        )
        return try await writeOurProfile(profile: updated)
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
        
        _ = try await self.noosphere.save()
        
        do {
            _ = try await self.noosphere.sync()
        } catch {
            // Swallow this error in the event syncing fails
            // Editing the profile still succeeded
            logger.warning("Failed to sync after updating profile: \(error.localizedDescription)")
        }
    }
    
//    func loadOurProfileFromMemo() async throws -> UserProfile {
//        let did = try await noosphere.identity()
//        let cid = try await noosphere.version()
//
//        return try await self.loadProfileFromMemo(
//            did: did,
//            address: Slashlink.ourProfile,
//            resolutionStatus: .resolved(cid)
//        )
//    }
    
//    nonisolated func loadOurProfileFromMemoPublisher(
//    ) -> AnyPublisher<UserProfile, Error> {
//        Future.detached {
//            try await self.loadOurProfileFromMemo()
//        }
//        .eraseToAnyPublisher()
//    }
    
    private func ourProfile() async throws -> UserProfile {
        let identity = try await self.noosphere.identity()
        
        return try await self.loadProfileFromMemo(
            did: identity,
            address: Slashlink.ourProfile
        )
    }
    
    func identifyUser(
        entry: AddressBookEntry,
        context: Peer?
    ) async throws -> UserProfile {
        return try await self.identifyUser(
            did: entry.did,
            petname: entry.petname,
            context: context
        )
    }
    
    func identifyUser(
        did: Did,
        address: Slashlink,
        context: Peer?
    ) async throws -> UserProfile {
        switch address.peer {
        case .petname(let petname):
            return try await self.identifyUser(did: did, petname: petname, context: context)
        case .did, .none:
            return try await self.identifyUser(did: did, petname: nil, context: context)
        }
    }
    
    /// Build a UserProfile suitable for list views, transcludes etc.
    /// This will attempt to read from the database and also maintain an in-memory cache of profiles
    /// we have encountered.
    func identifyUser(
        did: Did,
        petname: Petname?,
        context: Peer?
    ) async throws -> UserProfile {
        let version = try await self.noosphere.version()
        
        if let cacheHit = self.cache[did],
           cacheHit.version == version {
            return cacheHit.profile
        }
        
        let identity = try await self.noosphere.identity()
        guard did != identity else {
            let profile = try await ourProfile()
            self.cache.updateValue(
                UserProfileCacheEntry(profile: profile, version: version),
                forKey: did
            )
            return profile
        }
        
        let following = await self.addressBook.followingStatus(did: did, expectedName: petname?.leaf)
        let address = Func.run {
            switch (petname, context) {
            case let (.some(petname), .some(peer)):
                return Slashlink(petname: petname).rebaseIfNeeded(peer: peer)
            case let (.some(petname), .none):
                return Slashlink(petname: petname)
            case (.none, .some(let peer)):
                return Slashlink.ourProfile.rebaseIfNeeded(peer: peer)
            case (.none, .none):
                return Slashlink.ourProfile
            }
        }
        
        let sparseProfile = UserProfile(
            did: did,
            nickname: nil,
            address: address,
            pfp: .generated(did),
            bio: nil,
            category: .human,
            ourFollowStatus: following,
            aliases: []
        )
        
        let profile = try await Func.run {
            switch following {
            case .following(let name):
                guard let dbProfile = try await self.readProfileFromDb(
                    address: Slashlink(petname: name.toPetname())
                ) else {
                    return sparseProfile
                }
                
                return UserProfile(
                    did: did,
                    nickname: Petname.Name(dbProfile.nickname ?? ""),
                    address: address,
                    pfp: .generated(did),
                    bio: UserProfileBio(dbProfile.bio ?? ""),
                    category: .human,
                    ourFollowStatus: following,
                    aliases: [petname, name.toPetname()].compactMap { $0 } // TODO: a bit too clever
                )
            case .notFollowing:
                return sparseProfile
            }
        }

        self.cache.updateValue(
            UserProfileCacheEntry(profile: profile, version: version),
            forKey: did
        )
        
        return profile
    }
    
//    /// Produces a `UserProfile` for the passed address.
//    /// If a `did` is provided we can skip resolution and return faster.
//    func buildUserProfile(
//        address: Slashlink,
//        did: Did
//    ) async throws -> UserProfile {
//        let profile = try await self.loadProfileFromMemo(
//            did: did,
//            address: Slashlink(peer: address.peer, slug: Slug.profile)
//        )
//
//        return profile
//    }
    
    private func cachedProfile(did: Did) async throws -> UserProfile? {
        let version = try await self.noosphere.version()
        
        if let cacheHit = self.cache[did],
           cacheHit.version == version {
            return cacheHit.profile
        }
        
        return nil
    }
    
    /// Read all data needed to render a user's profile.
    /// Recent entries are read from the DB if we follow this user, otherwise we traverse to and list the sphere.
    /// The user profile (nickname, bio, following list) are read directly from the sphere and never cached.
    func loadFullProfileData(
        address: Slashlink
    ) async throws -> UserProfileContentResponse {
        let sphere = try await self.noosphere.sphere(address: address)
        let did = try await sphere.identity()
        
        let following = try await self.getFollowingList(
            address: address,
            sphere: sphere
        )
        let followingStatus = await self.addressBook.followingStatus(
            did: did,
            expectedName: address.petname?.leaf
        )
        
        let entries = try await Func.run {
            switch (followingStatus) {
            // Read from DB if we follow this user
            case .following(let name):
                // Ensure the index is ready, we might have JUST followed this user
                let lastIndex = try? database.readPeer(identity: did)
                guard lastIndex != nil else {
                    break
                }
                
                return try
                    self.database.listRecentMemos(owner: did, includeDrafts: false)
                    .map { memo in
                        memo.withAddress(
                            Slashlink(
                                petname: name.toPetname(),
                                slug: memo.address.slug
                            )
                        )
                    }
            // Otherwise, traverse the noosphere
            case .notFollowing:
                break
            }
            
            let notes = try await sphere.list()
            return try await self.loadEntries(
                address: address,
                slugs: notes
            )
        }
        
        let recentEntries = sortEntriesByModified(entries: entries)
        let profile = try await self.loadProfileFromMemo(
            did: did,
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
            followingStatus: followingStatus
        )
    }
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func requestOurProfile() async throws -> UserProfileContentResponse {
        try await loadFullProfileData(address: Slashlink.ourProfile)
    }
    
    nonisolated func requestOurProfilePublisher(
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
        try await loadFullProfileData(address: Slashlink(petname: petname))
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
