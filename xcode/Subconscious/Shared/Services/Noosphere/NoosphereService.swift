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
import SwiftNoosphere
import os
import Combine

enum NoosphereServiceError: Error, LocalizedError {
    case defaultSphereNotFound
    
    var errorDescription: String? {
        switch self {
        case .defaultSphereNotFound:
            return "Default sphere not found"
        }
    }
}

/// Creates and manages Noosphere and default sphere singletons.
actor NoosphereService: SphereProtocol, SphereIdentityProtocol {
    /// Default logger for NoosphereService instances.
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "NoosphereService"
    )

    private var logger: Logger
    var globalStorageURL: URL
    var sphereStorageURL: URL
    var gatewayURL: URL?
    /// Memoized Noosphere instance
    private var _noosphere: Noosphere?
    /// Identity of default sphere
    private var _sphereIdentity: String?
    /// Memoized Sphere instance
    private var _sphere: Sphere?
    
    init(
        globalStorageURL: URL,
        sphereStorageURL: URL,
        gatewayURL: URL? = nil,
        sphereIdentity: String? = nil,
        logger: Logger = logger
    ) {
        logger.debug("init NoosphereService")
        logger.debug("Global storage URL: \(globalStorageURL.absoluteString)")
        logger.debug("Sphere storage URL: \(sphereStorageURL.absoluteString)")
        logger.debug("Gateway URL: \(gatewayURL?.absoluteString ?? "none")")
        logger.debug("Sphere identity: \(sphereIdentity ?? "none")")
        self.globalStorageURL = globalStorageURL
        self.sphereStorageURL = sphereStorageURL
        self.gatewayURL = gatewayURL
        self._sphereIdentity = sphereIdentity
        self.logger = logger
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
    func resetSphere(_ identity: String?) {
        logger.debug("Reset sphere identity: \(identity ?? "none")")
        self._sphereIdentity = identity
        self._sphere = nil
    }
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func resetGateway(url: URL?) {
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
            gatewayURL: gatewayURL?.absoluteString
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
            identity: identity
        )
        self._sphere = sphere
        return sphere
    }
    
    func identity() throws -> String {
        try self.sphere().identity
    }

    func version() async throws -> String {
        try await self.sphere().version()
    }
    
    func getFileVersion(slashlink: Slashlink) async -> String? {
        try? await self.sphere().getFileVersion(slashlink: slashlink)
    }
    
    func readHeaderValueFirst(
        slashlink: Slashlink, name: String
    ) async -> String? {
        try? await self.sphere().readHeaderValueFirst(
            slashlink: slashlink,
            name: name
        )
    }
    
    func readHeaderNames(slashlink: Slashlink) async -> [String] {
        guard let names = try? await self.sphere().readHeaderNames(
            slashlink: slashlink
        ) else {
            return []
        }
        return names
    }
    
    func read(slashlink: Slashlink) async throws -> MemoData {
        try await self.sphere().read(slashlink: slashlink)
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
    
    func remove(slug: Slug) async throws {
        try await self.sphere().remove(slug: slug)
    }
    
    @discardableResult func save() async throws -> String {
        try await self.sphere().save()
    }
    
    func list() async throws -> [Slug] {
        try await self.sphere().list()
    }
    
    func sync() async throws -> String {
        try await self.sphere().sync()
    }
    
    func changes(_ since: String?) async throws -> [Slug] {
        try await self.sphere().changes(since)
    }
    
    func getPetname(petname: Petname) async throws -> String {
        try await self.sphere().getPetname(petname: petname)
    }
    
    func setPetname(did: String, petname: Petname) async throws {
        try await self.sphere().setPetname(did: did, petname: petname)
    }
    
    func unsetPetname(petname: Petname) async throws {
        try await self.sphere().unsetPetname(petname: petname)
    }
    
    func resolvePetname(petname: Petname) async throws -> String {
        try await self.sphere().resolvePetname(petname: petname)
    }
    
    func listPetnames() async throws -> [Petname] {
        try await self.sphere().listPetnames()
    }
    
    func getPetnameChanges(sinceCid: String) async throws -> [Petname] {
        try await self.sphere().getPetnameChanges(sinceCid: sinceCid)
    }

    func traverse(petname: Petname) async throws -> Sphere {
        try await self.sphere().traverse(petname: petname)
    }
}
