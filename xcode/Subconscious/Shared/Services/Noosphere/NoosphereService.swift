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
    
    var errorDescription: String? {
        switch self {
        case .defaultSphereNotFound:
            return "Default sphere not found"
        }
    }
}

/// Creates and manages Noosphere and default sphere singletons.
final class NoosphereService: SphereProtocol, SpherePublisherProtocol {
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
    func createSphere(ownerKeyName: String) throws -> SphereReceipt {
        try self.noosphere().createSphere(
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
    
    private func spherePublisher() -> AnyPublisher<Sphere, Error> {
        Future {
            try self.sphere()
        }
        .eraseToAnyPublisher()
    }

    func identity() throws -> String {
        try self.sphere().identity
    }

    func version() throws -> String {
        try self.sphere().version()
    }
    
    func versionPublisher() -> AnyPublisher<String, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.versionPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func getFileVersion(slashlink: Slashlink) -> String? {
        try? self.sphere().getFileVersion(slashlink: slashlink)
    }
    
    func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<String?, Never> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getFileVersionPublisher(slashlink: slashlink)
        }).catch({ error in
            Just(nil)
        })
        .eraseToAnyPublisher()
    }
    
    func readHeaderValueFirst(slashlink: Slashlink, name: String) -> String? {
        try? self.sphere().readHeaderValueFirst(
            slashlink: slashlink,
            name: name
        )
    }
    
    func readHeaderValueFirstPublisher(
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
    
    func readHeaderNames(slashlink: Slashlink) -> [String] {
        guard let names = try? self.sphere().readHeaderNames(
            slashlink: slashlink
        ) else {
            return []
        }
        return names
    }
    
    func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never> {
        self.spherePublisher().flatMap({ sphere in
            sphere.readHeaderNamesPublisher(slashlink: slashlink)
        }).catch({ error in
            Just([])
        }).eraseToAnyPublisher()
    }
    
    func read(slashlink: Slashlink) throws -> MemoData {
        try self.sphere().read(slashlink: slashlink)
    }
    
    func readPublisher(slashlink: Slashlink) -> AnyPublisher<MemoData, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.readPublisher(slashlink: slashlink)
        }).eraseToAnyPublisher()
    }
    
    func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) throws {
        try self.sphere().write(
            slug: slug,
            contentType: contentType,
            additionalHeaders: additionalHeaders,
            body: body
        )
    }
    
    func writePublisher(
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

    func remove(slug: Slug) throws {
        try self.sphere().remove(slug: slug)
    }
    
    func removePublisher(slug: Slug) -> AnyPublisher<Void, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.removePublisher(slug: slug)
        }).eraseToAnyPublisher()
    }
    
    @discardableResult func save() throws -> String {
        try self.sphere().save()
    }
    
    func savePublisher() -> AnyPublisher<String, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.savePublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func list() throws -> [Slug] {
        try self.sphere().list()
    }
    
    func listPublisher() -> AnyPublisher<[Slug], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.listPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func sync() throws -> String {
        try self.sphere().sync()
    }
    
    func syncPublisher() -> AnyPublisher<String, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.syncPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func changes(_ since: String?) throws -> [Slug] {
        try self.sphere().changes(since)
    }
    
    func changesPublisher(_ since: String?) -> AnyPublisher<[Slug], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.changesPublisher(since)
        })
        .eraseToAnyPublisher()
    }
    
    func getPetname(petname: Petname) throws -> String {
        try self.sphere().getPetname(petname: petname)
    }
    
    func getPetnamePublisher(petname: Petname) -> AnyPublisher<String, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getPetnamePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func setPetname(did: String?, petname: Petname) throws {
        try self.sphere().setPetname(did: did, petname: petname)
    }
    
    func setPetnamePublisher(
        did: String?,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.setPetnamePublisher(did: did, petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func resolvePetname(petname: Petname) throws -> String {
        try self.sphere().resolvePetname(petname: petname)
    }
    
    func resolvePetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<String, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.resolvePetnamePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
    
    func listPetnames() throws -> [Petname] {
        try self.sphere().listPetnames()
    }
    
    func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.listPetnamesPublisher()
        })
        .eraseToAnyPublisher()
    }
    
    func getPetnameChanges(sinceCid: String) throws -> [Petname] {
        try self.sphere().getPetnameChanges(sinceCid: sinceCid)
    }
    
    func getPetnameChangesPublisher(
        sinceCid: String
    ) -> AnyPublisher<[Petname], Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.getPetnameChangesPublisher(sinceCid: sinceCid)
        })
        .eraseToAnyPublisher()
    }

    func traverse(petname: Petname) throws -> Sphere {
        try self.sphere().traverse(petname: petname)
    }
    
    func traversePublisher(petname: Petname) -> AnyPublisher<Sphere, Error> {
        self.spherePublisher().flatMap({ sphere in
            sphere.traversePublisher(petname: petname)
        })
        .eraseToAnyPublisher()
    }
}
