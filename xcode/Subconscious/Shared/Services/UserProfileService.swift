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
    case attemptToReadProfileFromInvalidAddress
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
        case .attemptToReadProfileFromInvalidAddress:
            return String(
                localized: "Tried to read a profile memo from a slashlink that does not use the profile slug.",
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
        }
    }
}

struct UserProfileContentResponse: Equatable, Hashable {
    var profile: UserProfile
    var statistics: UserProfileStatistics
    var recentEntries: [EntryStub]
    var following: [StoryUser]
    var followingStatus: UserProfileFollowStatus
    var likes: [Slashlink]
}

struct UserProfileEntry: Codable, Equatable, Hashable {
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

actor UserProfileService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBookService
    private var userLikes: UserLikesService
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
        addressBook: AddressBookService,
        userLikes: UserLikesService
    ) {
        self.noosphere = noosphere
        self.database = database
        self.addressBook = addressBook
        self.userLikes = userLikes
        
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
        // ensure keys are sorted on write to maintain content hash
        self.jsonEncoder.outputFormatting = .sortedKeys
    }
    
    private func parseProfile(
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
    
    /// Attempt to read & deserialize a user `_profile_.json` at the given address.
    /// Because profile data is optional and we expect it will not always be present
    /// any errors are logged & handled and nil will be returned if reading fails.
    func readProfileMemo(
        sphere: SphereProtocol
    ) async -> UserProfileEntry? {
        let identity = try? await sphere.identity()
        do {
            let data = try? await sphere.read(slashlink: Slashlink(slug: Slug.profile))
            guard let data = data else {
                return nil
            }
            
            guard data.contentType == Self.profileContentType else {
                throw UserProfileServiceError.unexpectedProfileContentType(data.contentType)
            }
            logger.log(
                "Read user profile at \(String(describing: identity))"
            )
            
            return try await parseProfile(body: data.body)
        } catch {
            logger.warning(
                "Failed to read profile at \(String(describing: identity)): \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    /// Attempt to read & deserialize a user `_profile_.json` from the indexed copy.
    /// This can only work for user's we follow & have indexed, otherwise it returns nil
    func readProfileFromDb(
        did: Did
    ) async throws -> UserProfileEntry? {
        guard let data = try database.readUserProfile(did: did) else {
            return nil
        }
        
        return try await parseProfile(body: data)
    }
    
    /// Load the underlying `_profile_` memo for a user and construct a `UserProfile` from it.
    private func loadProfileFromMemo(
        sphere: SphereProtocol,
        address: Slashlink,
        alias: Petname?
    ) async throws -> UserProfile {
        let noosphereIdentity = try await noosphere.identity()
        let identity = try await sphere.identity()
        let isOurs = noosphereIdentity == identity
        
        logger.log("Read profile memo")
        let userProfileData = await self.readProfileMemo(sphere: sphere)
        
        let followingStatus = await self.addressBook.followingStatus(
            did: identity,
            expectedName: address.petname?.leaf
        )
        
        logger.log("List aliases")
        var aliases = try await self.addressBook.listAliases(did: identity)
        if let nickname = Petname.Name(userProfileData?.nickname ?? "") {
            aliases.append(nickname.toPetname())
        }
        
        if let petname = address.petname {
            aliases.append(petname)
        }
        
        if let alias = alias {
            aliases.append(alias)
        }
        
        let profile = UserProfile(
            did: identity,
            nickname: Petname.Name(userProfileData?.nickname ?? ""),
            address: address,
            pfp: .generated(identity),
            bio: UserProfileBio(userProfileData?.bio ?? ""),
            category: isOurs ? UserCategory.ourself : UserCategory.human,
            ourFollowStatus: followingStatus,
            aliases: aliases
        )
        
        return profile
    }
    
    /// Takes a list of slugs and prepares an `EntryStub` for each, excluding hidden slugs.
    private func loadEntries(
        sphere: SphereProtocol,
        address: Slashlink,
        slugs: [Slug]
    ) async throws -> [EntryStub] {
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
            
            let excerpt = Subtext.excerpt(markup: memo.body)

            entries.append(
                EntryStub(
                    did: identity,
                    address: Slashlink(
                        petname: address.petname,
                        slug: slug
                    ),
                    excerpt: excerpt,
                    headers: memo.wellKnownHeaders()
                )
            )
        }
        
        return entries
    }
    
    /// Produce a reverse-chronological list of the entries passed in
    private func sortEntriesByModified(entries: [EntryStub]) -> [EntryStub] {
        var recentEntries = entries
        recentEntries.sort(by: { a, b in
            a.headers.modified > b.headers.modified
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
            let user = try await self.identifyUser(entry: entry, context: address.petname)
            following.append(
                StoryUser(entry: entry, user: user)
            )
        }
        
        return following
    }
    
    /// Sets our nickname, preserving existing profile data.
    /// This is intended to be idempotent for use in the onboarding flow.
    func updateOurNickname(nickname: Petname.Name) async throws {
        guard let profile = await readProfileMemo(sphere: self.noosphere) else {
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

    func readOurProfile(alias: Petname?) async throws -> UserProfile {
        
        return try await self.loadProfileFromMemo(
            sphere: self.noosphere,
            address: Slashlink.ourProfile,
            alias: alias
        )
    }
    
    /// Build a UserProfile suitable for list views, transcludes etc.
    /// This will attempt to read from the database and also maintain an in-memory cache of profiles
    /// we have encountered.
    ///
    /// `context` will be used to determine the preferred navigation address for a user.
    func identifyUser(
        entry: AddressBookEntry,
        context: Petname?
    ) async throws -> UserProfile {
        return try await self.identifyUser(
            did: entry.did,
            petname: entry.petname,
            context: context
        )
    }
    
    /// Build a UserProfile suitable for list views, transcludes etc.
    /// This will attempt to read from the database and also maintain an in-memory cache of profiles
    /// we have encountered.
    ///
    /// `context` will be used to determine the preferred navigation address for a user.
    func identifyUser(
        did: Did,
        address: Slashlink,
        context: Petname?
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
    ///
    /// `context` will be used to determine the preferred navigation address for a user.
    func identifyUser(
        did: Did,
        petname: Petname?,
        context: Petname?
    ) async throws -> UserProfile {
        // Special case: our profile
        let identity = try await self.noosphere.identity()
        guard did != identity else {
            return try await readOurProfile(alias: petname)
        }
        
        let following = await self.addressBook.followingStatus(
            did: did,
            expectedName: petname?.leaf
        )
        
        // Determine the preferred navigation address for a user
        // If we follow someone, use our petname for then to visit their profile
        // If this is us, chop off the petname altogether
        let address = Func.run {
            switch (petname, context) {
            case let (.some(petname), .some(context)):
                return Slashlink(petname: petname).rebaseIfNeeded(peer: .petname(context))
            case let (.some(petname), .none):
                return Slashlink(petname: petname)
            case (.none, .some(let context)):
                return Slashlink.ourProfile.rebaseIfNeeded(peer: .petname(context))
            case (.none, .none):
                return Slashlink.ourProfile
            }
        }
        
        var aliases = try await self.addressBook.listAliases(did: did)
        if let petname = petname {
            aliases.append(petname)
        }
        
        let sparseProfile = UserProfile(
            did: did,
            nickname: nil,
            address: address,
            pfp: .generated(did),
            bio: nil,
            category: .human,
            ourFollowStatus: following,
            aliases: aliases
        )
        
        let profile = try await Func.run {
            switch following {
            case .following:
                guard let dbProfile = try await self.readProfileFromDb(
                    did: did
                ) else {
                    return sparseProfile
                }
                
                // Collect all the possible names for this user
                if let nickname = Petname.Name(dbProfile.nickname ?? "")?.toPetname() {
                    aliases.append(nickname)
                }
                
                return UserProfile(
                    did: did,
                    nickname: Petname.Name(dbProfile.nickname ?? ""),
                    address: address,
                    pfp: .generated(did),
                    bio: UserProfileBio(dbProfile.bio ?? ""),
                    category: .human,
                    ourFollowStatus: following,
                    aliases: aliases
                )
            case .notFollowing:
                return sparseProfile
            }
        }
        
        return profile
    }
    
    /// Read all data needed to render a user's profile.
    /// Recent entries are read from the DB if we follow this user, otherwise we traverse to and list the sphere.
    /// The user profile (nickname, bio, following list) are read directly from the sphere and never cached.
    func loadFullProfileData(
        address: Slashlink
    ) async throws -> UserProfileContentResponse {
        logger.log("Opening sphere...")
        let sphere = try await self.noosphere.sphere(address: address)
        let did = try await sphere.identity()
        logger.log("Opened sphere \(did)")
        
        logger.log("Load profile memo")
        let profile = try await self.loadProfileFromMemo(
            sphere: sphere,
            address: address,
            alias: address.petname
        )
        
        logger.log("Produce following list")
        let following = try await self.getFollowingList(
            address: address,
            sphere: sphere
        )
        logger.log("Get following status")
        let followingStatus = await self.addressBook.followingStatus(
            did: did,
            expectedName: address.petname?.leaf
        )
        
        logger.log("Read entries")
        let entries = try await Func.run {
            switch (followingStatus) {
            // Read from DB if we follow this user
            case .following(let name):
                logger.log("Check for local index")
                // Ensure the index is ready, we might have JUST followed this user
                let lastIndex = try? database.readPeer(identity: did)
                guard lastIndex != nil else {
                    break
                }
                
                logger.log("List from local index")
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
            
            logger.log("List from sphere itself")
            let notes = try await sphere.list()
            return try await self.loadEntries(
                sphere: sphere,
                address: address,
                slugs: notes
            )
        }
        let likes = await userLikes.readLikesMemo(sphere: sphere) ?? UserLikesEntry(likes: [])
        let recentEntries = sortEntriesByModified(entries: entries)
        
        logger.log("Assemble response")
        return UserProfileContentResponse(
            profile: profile,
            statistics: UserProfileStatistics(
                noteCount: entries.count,
                likeCount: likes.collection.count,
                followingCount: following.count
            ),
            recentEntries: recentEntries,
            following: following,
            followingStatus: followingStatus,
            likes: likes.collection
        )
    }
    
    /// Retrieve all the content for the App User's profile view, fetching their profile, notes and address book.
    func loadOurFullProfileData() async throws -> UserProfileContentResponse {
        try await loadFullProfileData(address: Slashlink.ourProfile)
    }
    
    nonisolated func loadOurFullProfileDataPublisher(
    ) -> AnyPublisher<UserProfileContentResponse, Error> {
        Future.detached {
            try await self.loadOurFullProfileData()
        }
        .eraseToAnyPublisher()
    }
}
