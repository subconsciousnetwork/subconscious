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
        self.collection = likes
    }
    
    var collection: [Slashlink]
}

actor UserLikesService {
    private var noosphere: NoosphereService
    private var jsonDecoder: JSONDecoder
    private var jsonEncoder: JSONEncoder
    
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "UserLikesService"
    )
    
    private static let collectionContentType = "application/vnd.subconscious.collection+json"
    private static let contentSchemaVersionHeader = "Content-Schema-Verson"
    
    init(noosphere: NoosphereService) {
        self.noosphere = noosphere
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
    func readLikesMemo(
        sphere: SphereProtocol
    ) async -> UserLikesEntry? {
        let identity = try? await sphere.identity()
        do {
            let data = try? await sphere.read(slashlink: Slashlink(slug: Slug.likes))
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
                "Failed to read likes at \(String(describing: identity)): \(error.localizedDescription)"
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
        var likes: UserLikesEntry =
            await self.readLikesMemo(sphere: self.noosphere)
                ?? UserLikesEntry(likes: [])
        
        likes.collection.append(address)
        
        try await self.writeOurLikes(likes: likes)
    }
    
    public func toggleLike(for address: Slashlink) async throws -> Void {
        var likes: UserLikesEntry =
            await self.readLikesMemo(sphere: self.noosphere)
                ?? UserLikesEntry(likes: [])
        
        if (likes.collection.contains(where: { like in like == address })) {
            likes.collection.removeAll(where: { like in like == address })
        } else {
            likes.collection.append(address)
        }
        
        try await self.writeOurLikes(likes: likes)
    }
    
    public func removeLike(for address: Slashlink) async throws -> Void {
        var likes: UserLikesEntry =
            await self.readLikesMemo(sphere: self.noosphere)
                ?? UserLikesEntry(likes: [])
        
        likes.collection.removeAll(where: { like in like == address })
        
        try await self.writeOurLikes(likes: likes)
    }
    
    public func readLikesFor(user: Slashlink) async throws -> [Slashlink] {
        let sphere = try await self.noosphere.sphere(address: user)
        guard let likes = await self.readLikesMemo(sphere: sphere) else {
            return []
        }
        
        return likes.collection
    }
    
    public func readOurLikes() async throws -> [Slashlink] {
        guard let likes = await self.readLikesMemo(sphere: self.noosphere) else {
            return []
        }
        
        return likes.collection
    }
    
    public func isLikedByUs(address: Slashlink) async throws -> Bool {
        let likes = try await self.readOurLikes()
        return likes.contains(where: { like in like == address })
    }
}
