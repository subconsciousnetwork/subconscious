//
//  UserLikesService.swift
//  Subconscious
//
//  Created by Ben Follington on 7/2/2024.
//

import Foundation
import os
import Combine

enum UserLikesServiceError: Error {
    case unexpectedProfileContentType(String)
    case unexpectedProfileSchemaVersion([Header])
    case failedToDeserializeProfile(Error, String?)
    case failedToPersistLike(Slashlink)
    case failedToRemoveLike(Slashlink)
    case failedToReadLikes
}

struct UserLikesEntry: Codable, Equatable, Hashable {
    static let currentVersion = "0.0"
    
    init(likes: [Slashlink]) {
        self.likes = likes
    }
    
    var likes: [Slashlink]
}

actor UserLikesService {
    private var noosphere: NoosphereService
    private var database: DatabaseService
    private var addressBook: AddressBookService
    private var jsonDecoder: JSONDecoder
    private var jsonEncoder: JSONEncoder
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserLikesService"
    )
    
    private static let collectionContentType = "application/vnd.subconscious.collection+json"
    private static let contentSchemaVersionHeader = "Content-Schema-Verson"
    
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
    
    private func parseLikes(
        body: Data
    ) async throws -> UserLikesEntry {
        do {
            return try jsonDecoder.decode(UserLikesEntry.self, from: body)
        } catch {
            // catch errors so we can give more context if there was a formatting error
            guard let string = String(data: body, encoding: .utf8) else {
                throw UserLikesServiceError.failedToDeserializeProfile(error, nil)
            }

            throw UserLikesServiceError.failedToDeserializeProfile(error, string)
        }
    }
    
    /// Attempt to read & deserialize a user `_likes_.json` at the given address.
    /// Because profile data is optional and we expect it will not always be present
    /// any errors are logged & handled and nil will be returned if reading fails.
    private func readLikesMemo(
        sphere: SphereProtocol
    ) async -> UserLikesEntry? {
        let identity = try? await sphere.identity()
        do {
            let data = try? await sphere.read(slashlink: Slashlink(slug: Slug.profile))
            guard let data = data else {
                return nil
            }
            
            guard data.additionalHeaders.contains(where: { header in
                header.name == Self.contentSchemaVersionHeader &&
                header.value == UserProfileEntry.currentVersion
            }) else {
                throw UserLikesServiceError.unexpectedProfileSchemaVersion(data.additionalHeaders)
            }
            
            guard data.contentType == Self.collectionContentType else {
                throw UserLikesServiceError.unexpectedProfileContentType(data.contentType)
            }
            logger.log(
                "Read user likes at \(String(describing: identity))"
            )
            
            return try await parseLikes(body: data.body)
        } catch {
            logger.warning(
                "Failed to read profile at \(String(describing: identity)): \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    /// Update our `_likes_` memo with the contents of the passed profile.
    /// This will save the underlying sphere and attempt to sync.
    func writeOurLikes(likes: UserLikesEntry) async throws {
        let data = try self.jsonEncoder.encode(likes)
        
        try await self.noosphere.write(
            slug: Slug.likes,
            contentType: Self.collectionContentType,
            additionalHeaders: [
                Header(
                    name: Self.contentSchemaVersionHeader,
                    value: UserLikesEntry.currentVersion
                )
            ],
            body: data
        )
        
        _ = try await self.noosphere.save()
    }
    
    public func persistLike(for address: Slashlink) async throws -> Void {
        guard var likes = await self.readLikesMemo(sphere: self.noosphere) else {
            throw UserLikesServiceError.failedToPersistLike(address)
        }
        
        likes.likes.append(address)
        
        try await self.writeOurLikes(likes: likes)
    }
    
    public func removeLike(for address: Slashlink) async throws -> Void {
        guard var likes = await self.readLikesMemo(sphere: self.noosphere) else {
            throw UserLikesServiceError.failedToRemoveLike(address)
        }
        
        likes.likes.removeAll(where: { like in like == address })
        
        try await self.writeOurLikes(likes: likes)
    }
    
    public func readLikesFor(user: Slashlink) async throws -> [Slashlink] {
        let sphere = try await self.noosphere.sphere(address: user)
        guard var likes = await self.readLikesMemo(sphere: sphere) else {
            throw UserLikesServiceError.failedToReadLikes
        }
        
        return likes.likes
    }
    
    public func readOurLikes() async throws -> [Slashlink] {
        guard var likes = await self.readLikesMemo(sphere: self.noosphere) else {
            throw UserLikesServiceError.failedToReadLikes
        }
        
        return likes.likes
    }
    
    public func isLiked(address: Slashlink) async throws -> Bool {
        let likes = try await self.readOurLikes()
        return likes.contains(where: { like in like == address })
    }
}
