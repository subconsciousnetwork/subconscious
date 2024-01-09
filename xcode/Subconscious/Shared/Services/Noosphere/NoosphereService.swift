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

extension NoosphereService {
    public func findBestAddressForLink(
        _ slashlink: Slashlink
    ) async throws -> Slashlink {
        let ourIdentity = try await self.identity()
        
        // We want the find the DID of this user so we can check if we follow them.
        // If we do follow them, we should prefer our petname for them when navigating.
        
        // i.e. I am following @bob, @alice and @charlie
        // I am viewing @bob's note /hello at @bob/hello
        // There is a link in @bob's note to @charlie.alice/hey
        // The relative address would be @charlie.alice.bob/hey
        // BUT if we resolve the address we realise that we know @charlie already!
        // So we rewrite the address to @charlie/hey
        
        // We _could_ also choose to simply bail out and navigate to the address without
        // traversing, at the expense of the clever redirect.
        var did: Did? = nil
        if let petname = slashlink.petname {
            did = try? await Func.run {
                let sphere = try await self.traverse(petname: petname)
                return try await sphere.identity()
            }
        }
        
        // No identity means we can't check following status
        guard let did = did else {
            return slashlink
        }
        
        // Is this address ours? Trim off the peer
        guard did != ourIdentity else {
            return Slashlink(slug: slashlink.slug)
        }
    
        // Are we following this user?
        let addressBook = AddressBook(sphere: self)
        let following = await addressBook.followingStatus(
            did: did,
            expectedName: nil
        )
        
        switch following {
        // Use the name we know for this user
        case .following(let name):
            return Slashlink(
                petname: name.toPetname(),
                slug: slashlink.slug
            )
        case .notFollowing:
            return slashlink
        }
    }
}

protocol NoosphereServiceProtocol {
    var globalStorageURL: URL { get async }
    var sphereStorageURL: URL { get async }
    var gatewayURL: GatewayURL? { get async }

    func createSphere(ownerKeyName: String) async throws -> SphereReceipt

    /// Set a new default sphere
    func resetSphere(_ identity: String?) async
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func resetGateway(url: GatewayURL?) async
    
    /// Reset managed instances of Noosphere and Sphere
    func reset() async
    
    func recover(identity: Did, gatewayUrl: GatewayURL, mnemonic: String) async throws -> Bool
}

/// Creates and manages Noosphere and default sphere singletons.
actor NoosphereService:
    SphereProtocol,
    SpherePublisherProtocol,
    NoosphereServiceProtocol
{
    private var logger = Logger(
        subsystem: Config.default.rdns,
        category: "NoosphereService"
    )
    var globalStorageURL: URL
    var sphereStorageURL: URL
    var gatewayURL: GatewayURL?
    private var _noosphereLogLevel: Noosphere.NoosphereLogLevel
    /// Memoized Noosphere instance
    private var _noosphere: Noosphere?
    /// Identity of default sphere
    private var _sphereIdentity: String?
    /// Memoized Sphere instance
    private var _sphere: Sphere?
    private var errorLoggingService: any ErrorLoggingServiceProtocol
    
    init(
        globalStorageURL: URL,
        sphereStorageURL: URL,
        gatewayURL: GatewayURL? = nil,
        sphereIdentity: String? = nil,
        noosphereLogLevel: Noosphere.NoosphereLogLevel = .basic,
        errorLoggingService: any ErrorLoggingServiceProtocol
    ) {
        logger.debug(
            "init NoosphereService",
            metadata: [
                "globalStorageURL": globalStorageURL.absoluteString,
                "sphereStorageURL": sphereStorageURL.absoluteString,
                "gatewayURL": gatewayURL?.absoluteString ?? "nil",
                "sphereIdentity": sphereIdentity ?? "nil"
            ]
        )
        self.globalStorageURL = globalStorageURL
        self.sphereStorageURL = sphereStorageURL
        self.gatewayURL = gatewayURL
        self._sphereIdentity = sphereIdentity
        self._noosphereLogLevel = noosphereLogLevel
        self.errorLoggingService = errorLoggingService
    }
    
    /// Create a default sphere for user and persist sphere details
    /// This creates, but does not save the sphere as default.
    /// - Returns: SphereReceipt
    func createSphere(ownerKeyName: String) async throws -> SphereReceipt {
        try await errorLoggingService.capturing {
            try await noosphere().createSphere(
                ownerKeyName: ownerKeyName
            )
        }
    }
    
    /// Set a new default sphere
    func resetSphere(_ identity: String?) {
        logger.log("Reset sphere identity: \(identity ?? "none")")
        self._sphereIdentity = identity
        self._sphere = nil
    }
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func resetGateway(url: GatewayURL?) {
        guard self.gatewayURL != url else {
            logger.debug("Reset gateway to identical URL, ignoring")
            return
        }
       
        logger.log("Reset gateway: \(url?.absoluteString ?? "none")")
        self.gatewayURL = url
        self._noosphere = nil
        self._sphere = nil
    }
    
    /// Reset managed instances of Noosphere and Sphere
    func reset() {
        logger.log("Reset cached instances of Noosphere and Sphere")
        self._noosphere = nil
        self._sphere = nil
    }
    
    /// Gets or creates memoized Noosphere singleton instance
    private func noosphere() throws -> Noosphere {
        if let noosphere = self._noosphere {
            return noosphere
        }
        logger.log("Initializing Noosphere")
        let noosphere = try Noosphere(
            globalStoragePath: globalStorageURL.path(percentEncoded: false),
            sphereStoragePath: sphereStorageURL.path(percentEncoded: false),
            gatewayURL: gatewayURL?.absoluteString,
            noosphereLogLevel: _noosphereLogLevel
        )
        self._noosphere = noosphere
        logger.log("Initialized and cached Noosphere")
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
        logger.log("Initializing Sphere with identity: \(identity)")
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: identity
        )
        self._sphere = sphere
        logger.log("Initialized and cached Sphere with identity: \(identity)")
        return sphere
    }
    
    func identity() async throws -> Did {
        try await errorLoggingService.capturing {
            try await sphere().identity()
        }
    }

    nonisolated func identityPublisher() -> AnyPublisher<Did, Error> {
        Future {
            try await self.identity()
        }
        .eraseToAnyPublisher()
    }

    func version() async throws -> Cid {
        try await errorLoggingService.capturing {
            try await sphere().version()
        }
    }
    
    nonisolated func versionPublisher() -> AnyPublisher<Cid, Error> {
        Future {
            try await self.version()
        }
        .eraseToAnyPublisher()
    }
    
    func getFileVersion(slashlink: Slashlink) async -> Cid? {
        try? await errorLoggingService.capturing {
            try await sphere().getFileVersion(slashlink: slashlink)
        }
    }
    
    nonisolated func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<Cid?, Never> {
        Future {
            await self.getFileVersion(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }
    
    func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) async -> String? {
        try? await errorLoggingService.capturing {
            try await sphere().readHeaderValueFirst(
                slashlink: slashlink,
                name: name
            )
        }
    }
    
    nonisolated func readHeaderValueFirstPublisher(
        slashlink: Slashlink,
        name: String
    ) -> AnyPublisher<String?, Never> {
        Future {
            await self.readHeaderValueFirst(slashlink: slashlink, name: name)
        }
        .eraseToAnyPublisher()
    }
    
    func readHeaderNames(slashlink: Slashlink) async -> [String] {
        let names = try? await errorLoggingService.capturing {
            try await sphere().readHeaderNames(
                slashlink: slashlink
            )
        }
        return names.unwrap(or: [])
    }
    
    nonisolated func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never> {
        Future {
            await self.readHeaderNames(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }
    
    func read(slashlink: Slashlink) async throws -> MemoData {
        try await errorLoggingService.capturing {
            try await sphere().read(slashlink: slashlink)
        }
    }
    
    nonisolated func readPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<MemoData, Error> {
        Future {
            try await self.read(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }
    
    func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) async throws {
        try await errorLoggingService.capturing {
            try await sphere().write(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }
    }
    
    nonisolated func writePublisher(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) -> AnyPublisher<Void, Error> {
        Future {
            try await self.write(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }
        .eraseToAnyPublisher()
    }

    func remove(slug: Slug) async throws {
        try await errorLoggingService.capturing {
            try await sphere().remove(slug: slug)
        }
    }
    
    nonisolated func removePublisher(slug: Slug) -> AnyPublisher<Void, Error> {
        Future {
            try await self.remove(slug: slug)
        }
        .eraseToAnyPublisher()
    }
    
    @discardableResult func save() async throws -> Cid {
        try await errorLoggingService.capturing {
            try await sphere().save()
        }
    }
    
    nonisolated func savePublisher() -> AnyPublisher<Cid, Error> {
        Future {
            try await self.save()
        }
        .eraseToAnyPublisher()
    }
    
    func list() async throws -> [Slug] {
        try await errorLoggingService.capturing {
            try await sphere().list()
        }
    }
    
    nonisolated func listPublisher() -> AnyPublisher<[Slug], Error> {
        Future {
            try await self.list()
        }
        .eraseToAnyPublisher()
    }
    
    func sync() async throws -> Cid {
        try await errorLoggingService.capturing {
            try await sphere().sync()
        }
    }
    
    nonisolated func syncPublisher() -> AnyPublisher<Cid, Error> {
        Future {
            try await self.sync()
        }
        .eraseToAnyPublisher()
    }
    
    func changes(since cid: String?) async throws -> [Slug] {
        try await errorLoggingService.capturing {
            try await sphere().changes(since: cid)
        }
    }
    
    nonisolated func changesPublisher(
        since cid: String?
    ) -> AnyPublisher<[Slug], Error> {
        Future {
            try await self.changes(since: cid)
        }
        .eraseToAnyPublisher()
    }
    
    func getPetname(petname: Petname) async throws -> Did {
        try await errorLoggingService.capturing {
            try await sphere().getPetname(petname: petname)
        }
    }
    
    nonisolated func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Did, Error> {
        Future {
            try await self.getPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    func setPetname(did: Did?, petname: Petname) async throws {
        try await errorLoggingService.capturing {
            try await sphere().setPetname(did: did, petname: petname)
        }
    }
    
    nonisolated func setPetnamePublisher(
        did: Did?,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future {
            try await self.setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    func resolvePetname(petname: Petname) async throws -> Cid {
        try await errorLoggingService.capturing {
            try await sphere().resolvePetname(petname: petname)
        }
    }
    
    nonisolated func resolvePetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Cid, Error> {
        Future {
            try await self.resolvePetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    func listPetnames() async throws -> [Petname] {
        try await errorLoggingService.capturing {
            try await sphere().listPetnames()
        }
    }
    
    nonisolated func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        Future {
            try await self.listPetnames()
        }
        .eraseToAnyPublisher()
    }
    
    func getPetnameChanges(since cid: Cid) async throws -> [Petname] {
        try await errorLoggingService.capturing {
            try await sphere().getPetnameChanges(since: cid)
        }
    }
    
    nonisolated func getPetnameChangesPublisher(
        since cid: String
    ) -> AnyPublisher<[Petname], Error> {
        Future {
            try await self.getPetnameChanges(since: cid)
        }
        .eraseToAnyPublisher()
    }

    func traverse(petname: Petname) async throws -> Sphere {
        try await errorLoggingService.capturing {
            try await sphere().traverse(petname: petname)
        }
    }
    
    func authorize(name: String, did: Did) async throws -> Authorization {
        try await errorLoggingService.capturing {
            try await sphere().authorize(name: name, did: did)
        }
    }
    
    func revoke(authorization: Authorization) async throws -> Void {
        try await errorLoggingService.capturing {
            try await sphere().revoke(authorization: authorization)
        }
    }
    
    func escalateAuthority(mnemonic: String) async throws -> Sphere {
        try await errorLoggingService.capturing {
            try await sphere().escalateAuthority(mnemonic: mnemonic)
        }
    }
    
    func listAuthorizations() async throws -> [Authorization] {
        try await errorLoggingService.capturing {
            try await sphere().listAuthorizations()
        }
    }
    
    func verify(authorization: Authorization) async throws -> Bool {
        try await errorLoggingService.capturing {
            try await sphere().verify(authorization: authorization)
        }
    }
    
    func recover(
        identity: Did,
        gatewayUrl: GatewayURL,
        mnemonic: String
    ) async throws -> Bool {
        // Update the gateway URL to whatever was in the form
        resetGateway(url: gatewayUrl)
        // Release the sphere before we attempt to recover it
        // If we don't do this the database LOCK will prevent us from recovering
        resetSphere(nil)
        
        return try await errorLoggingService.capturing {
            let result = try await noosphere().recover(
                identity: identity,
                localKeyName: Config.default.noosphere.ownerKeyName,
                mnemonic: mnemonic
            )
            
            resetSphere(identity.did)
            
            return result
        }
    }
    
    /// Intelligently open a sphere by traversing or, if this is our address, returning the default sphere.
    func sphere(address: Slashlink) async throws -> Sphere {
        let identity = try await self.identity()
        
        switch address.peer {
        case .none:
            return try await errorLoggingService.capturing {
                try self.sphere()
            }
        case .did(let did) where did == identity:
            return try await errorLoggingService.capturing {
                try self.sphere()
            }
        case .petname(let petname):
            return try await self.traverse(petname: petname)
        default:
            throw NoosphereServiceError.cannotFindSphereForUnknownIdentity
        }
    }
    
    nonisolated func traversePublisher(
        petname: Petname
    ) -> AnyPublisher<Sphere, Error> {
        Future {
            try await self.sphere().traverse(petname: petname)
        }
        .eraseToAnyPublisher()
    }
}
