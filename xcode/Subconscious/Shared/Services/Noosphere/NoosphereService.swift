//
//  NoosphereService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/10/23.
//
//  Noosphere lifecycle:
//  1. Initialize namespace (once ever)
//  2. Create a unique key (once per key)
//  3. Create sphere for key, getting back a receipt (once per key)
//     - Retrieve identity from sphere receipt, then store (once, upon sphere creation)
//     - Retrieve sphere mnemonic from sphere receipt. Display to user, then discard (once, upon sphere creation)
//  4. Open sphere file system (on-demand)

import Foundation
import Combine
import SwiftNoosphere
import os

enum NoosphereServiceError: Error, LocalizedError {
    case defaultSphereNotFound
    case cannotFindSphereForUnknownIdentity
    
    var errorDescription: String? {
        switch self {
        case .defaultSphereNotFound:
            return "Default sphere not found"
        case .cannotFindSphereForUnknownIdentity:
            return "Attempted to open a sphere using an unknown DID, this is unsupported."
        }
    }
}

protocol NoosphereServiceProtocol {
    var globalStorageURL: URL { get async }
    var sphereStorageURL: URL { get async }
    var gatewayURL: URL? { get async }

    func createSphere(ownerKeyName: String) async throws -> SphereReceipt

    /// Set a new default sphere
    func resetSphere(_ identity: Did?) async
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func resetGateway(url: URL?) async
    
    /// Reset managed instances of Noosphere and Sphere
    func reset() async
}

/// Creates and manages Noosphere and default sphere singletons.
actor NoosphereService:
    SphereProtocol,
    SpherePublisherProtocol,
    NoosphereServiceProtocol
{
    /// Default logger for NoosphereService instances.
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "NoosphereService"
    )

    private var logger: Logger
    var globalStorageURL: URL
    var sphereStorageURL: URL
    var gatewayURL: URL?
    private var _noosphereLogLevel: Noosphere.NoosphereLogLevel
    /// Memoized Noosphere instance
    private var _noosphere: Noosphere?
    /// Identity of default sphere
    private var _sphereIdentity: Did?
    /// Memoized Sphere instance
    private var _sphere: Sphere?
    
    init(
        globalStorageURL: URL,
        sphereStorageURL: URL,
        gatewayURL: URL? = nil,
        sphereIdentity: Did? = nil,
        noosphereLogLevel: Noosphere.NoosphereLogLevel = .basic,
        logger: Logger = logger
    ) {
        logger.debug(
            "init NoosphereService",
            metadata: [
                "globalStorageURL": globalStorageURL.absoluteString,
                "sphereStorageURL": sphereStorageURL.absoluteString,
                "gatewayURL": gatewayURL?.absoluteString ?? "nil",
                "sphereIdentity": sphereIdentity?.description
            ]
        )

        self.globalStorageURL = globalStorageURL
        self.sphereStorageURL = sphereStorageURL
        self.gatewayURL = gatewayURL
        self._sphereIdentity = sphereIdentity
        self.logger = logger
        self._noosphereLogLevel = noosphereLogLevel
    }
    
    /// Create a default sphere for user and persist sphere details
    /// This creates, but does not save the sphere as default.
    /// - Returns: SphereReceipt
    func createSphere(ownerKeyName: String) async throws -> SphereReceipt {
        try await self.noosphere().createSphere(
            ownerKeyName: ownerKeyName
        )
    }
    
    /// Set a new default sphere
    func resetSphere(_ identity: Did?) {
        if let identity = identity {
            logger.debug("Reset sphere identity: \(identity)")
        } else {
            logger.debug("Cleared sphere identity")
        }
        
        self._sphereIdentity = identity
        self._sphere = nil
    }
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func resetGateway(url: URL?) {
        guard self.gatewayURL != url else {
            logger.debug("Reset gateway to identical URL, ignoring")
            return
        }
       
        logger.debug("Reset gateway: \(url?.absoluteString ?? "none")")
        self.gatewayURL = url
        self._noosphere = nil
        self._sphere = nil
    }
    
    /// Reset managed instances of Noosphere and Sphere
    func reset() {
        logger.debug("Reset memoized instances of Noosphere and Sphere")
        self._noosphere = nil
        self._sphere = nil
    }
    
    /// Gets or creates memoized Noosphere singleton instance
    private func noosphere() throws -> Noosphere {
        if let noosphere = self._noosphere {
            return noosphere
        }
        logger.debug("init Noosphere")
        let noosphere = try Noosphere(
            globalStoragePath: globalStorageURL.path(percentEncoded: false),
            sphereStoragePath: sphereStorageURL.path(percentEncoded: false),
            gatewayURL: gatewayURL?.absoluteString,
            noosphereLogLevel: _noosphereLogLevel
        )
        self._noosphere = noosphere
        return noosphere
    }
    
    /// Get or open default Sphere.
    private func sphere() throws -> Sphere {
        if let sphere = self._sphere {
            return sphere
        }
        guard let identity = self._sphereIdentity else {
            throw NoosphereServiceError.defaultSphereNotFound
        }
        
        let noosphere = try noosphere()
        logger.debug("init Sphere with identity: \(identity)")
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: identity.did
        )
        self._sphere = sphere
        return sphere
    }
    
    nonisolated private func spherePublisher() -> AnyPublisher<Sphere, Error> {
        Future {
            try await self.sphere()
        }
        .eraseToAnyPublisher()
    }

    func identity() async throws -> Did {
        try await self.sphere().identity()
    }

    nonisolated func identityPublisher() -> AnyPublisher<Did, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.identityPublisher()
        })
        .eraseToAnyPublisher()
    }

    func version() async throws -> Cid {
        try await self.sphere().version()
    }
    
    nonisolated func versionPublisher() -> AnyPublisher<Cid, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.versionPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func getFileVersion(slashlink: Slashlink) async -> Cid? {
        try? await self.sphere().getFileVersion(slashlink: slashlink)
    }
    
    nonisolated func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<Cid?, Never> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getFileVersionPublisher(slashlink: slashlink)
        }).catch({ error in
            Just(nil)
        })
        .eraseToAnyPublisher()
    }
    
    func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) async -> String? {
        try? await self.sphere().readHeaderValueFirst(
            slashlink: slashlink,
            name: name
        )
    }
    
    nonisolated func readHeaderValueFirstPublisher(
        slashlink: Slashlink,
        name: String
    ) -> AnyPublisher<String?, Never> {
        self.spherePublisher().flatMap({ sphere in
            sphere.readHeaderValueFirstPublisher(
                slashlink: slashlink,
                name: name
            )
        }).catch({ error in
            Just(nil)
        }).eraseToAnyPublisher()
    }
    
    func readHeaderNames(slashlink: Slashlink) async -> [String] {
        guard let names = try? await self.sphere().readHeaderNames(
            slashlink: slashlink
        ) else {
            return []
        }
        return names
    }
    
    nonisolated func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never> {
        self.spherePublisher().flatMap({ sphere in
            sphere.readHeaderNamesPublisher(slashlink: slashlink)
        }).catch({ error in
            Just([])
        }).eraseToAnyPublisher()
    }
    
    func read(slashlink: Slashlink) async throws -> MemoData {
        try await self.sphere().read(slashlink: slashlink)
    }
    
    nonisolated func readPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<MemoData, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.readPublisher(slashlink: slashlink)
        }).eraseToAnyPublisher()
    }
    
    func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) async throws {
        try await self.sphere().write(
            slug: slug,
            contentType: contentType,
            additionalHeaders: additionalHeaders,
            body: body
        )
    }
    
    nonisolated func writePublisher(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) -> AnyPublisher<Void, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.writePublisher(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }).eraseToAnyPublisher()
    }

    func remove(slug: Slug) async throws {
        try await self.sphere().remove(slug: slug)
    }
    
    nonisolated func removePublisher(slug: Slug) -> AnyPublisher<Void, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.removePublisher(slug: slug)
        }).eraseToAnyPublisher()
    }
    
    @discardableResult func save() async throws -> Cid {
        try await self.sphere().save()
    }
    
    nonisolated func savePublisher() -> AnyPublisher<Cid, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.savePublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func list() async throws -> [Slug] {
        try await self.sphere().list()
    }
    
    nonisolated func listPublisher() -> AnyPublisher<[Slug], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.listPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func sync() async throws -> Cid {
        try await self.sphere().sync()
    }
    
    nonisolated func syncPublisher() -> AnyPublisher<Cid, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.syncPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func changes(since cid: String?) async throws -> [Slug] {
        try await self.sphere().changes(since: cid)
    }
    
    nonisolated func changesPublisher(
        since cid: String?
    ) -> AnyPublisher<[Slug], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.changesPublisher(since: cid)
        })
        .eraseToAnyPublisher()
    }
    
    func getPetname(petname: Petname) async throws -> Did {
        try await self.sphere().getPetname(petname: petname)
    }
    
    nonisolated func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Did, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getPetnamePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func setPetname(did: Did?, petname: Petname) async throws {
        try await self.sphere().setPetname(did: did, petname: petname)
    }
    
    nonisolated func setPetnamePublisher(
        did: Did?,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.setPetnamePublisher(did: did, petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func resolvePetname(petname: Petname) async throws -> Cid {
        try await self.sphere().resolvePetname(petname: petname)
    }
    
    nonisolated func resolvePetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Cid, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.resolvePetnamePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func listPetnames() async throws -> [Petname] {
        try await self.sphere().listPetnames()
    }
    
    nonisolated func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.listPetnamesPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func getPetnameChanges(since cid: Cid) async throws -> [Petname] {
        try await self.sphere().getPetnameChanges(since: cid)
    }
    
    nonisolated func getPetnameChangesPublisher(
        since cid: String
    ) -> AnyPublisher<[Petname], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getPetnameChangesPublisher(since: cid)
        })
        .eraseToAnyPublisher()
    }

    func traverse(petname: Petname) async throws -> Sphere {
        try await self.sphere().traverse(petname: petname)
    }
    
    func authorize(name: String, did: Did) async throws -> Authorization {
        try await self.sphere().authorize(name: name, did: did)
    }
    
    func revoke(authorization: Authorization) async throws -> Void {
        try await self.sphere().revoke(authorization: authorization)
    }
    
    func escalateAuthority(mnemonic: String) async throws -> Sphere {
        try await self.sphere().escalateAuthority(mnemonic: mnemonic)
    }
    
    func listAuthorizations() async throws -> [Authorization] {
        try await self.sphere().listAuthorizations()
    }
    
    func verify(authorization: Authorization) async throws -> Bool {
        try await self.sphere().verify(authorization: authorization)
    }
    
    /// Intelligently open a sphere by traversing or, if this is our address, returning the default sphere.
    func sphere(address: Slashlink) async throws -> Sphere {
        let identity = try await self.identity()
        
        switch address.peer {
        case .none:
            return try self.sphere()
        case .did(let did) where did == identity:
            return try self.sphere()
        case .petname(let petname):
            return try await self.traverse(petname: petname)
        default:
            throw NoosphereServiceError.cannotFindSphereForUnknownIdentity
        }
    }
    
    nonisolated func traversePublisher(
        petname: Petname
    ) -> AnyPublisher<Sphere, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.traversePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
}
