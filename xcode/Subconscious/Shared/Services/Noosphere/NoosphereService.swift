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

enum NoosphereServiceError: Error {
    case defaultSphereNotFound
}

/// Creates and manages Noosphere and default sphere singletons.
final class NoosphereService: SphereProtocol {
    var globalStorageURL: URL
    var sphereStorageURL: URL
    var gatewayURL: URL?
    /// Memoized Noosphere instance
    private var _noosphere: Noosphere?
    /// Identity of default sphere
    private var _sphereIdentity: String?
    /// Memoized Sphere instance
    private var _sphere: SphereFS?
    
    init(
        globalStorageURL: URL,
        sphereStorageURL: URL,
        gatewayURL: URL? = nil,
        sphereIdentity: String?
    ) {
        self.globalStorageURL = globalStorageURL
        self.sphereStorageURL = sphereStorageURL
        self.gatewayURL = gatewayURL
        self._sphereIdentity = sphereIdentity
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
    func updateDefaultSphere(_ identity: String?) {
        self._sphereIdentity = identity
        self._sphere = nil
    }
    
    /// Update Gateway.
    /// Resets memoized Noosphere and Sphere instances.
    func updateGateway(url: URL?) {
        self.gatewayURL = url
        self._noosphere = nil
        self._sphere = nil
    }
    
    /// Gets or creates memoized Noosphere singleton instance
    private func noosphere() throws -> Noosphere {
        if let noosphere = self._noosphere {
            return noosphere
        }
        let noosphere = try Noosphere(
            globalStoragePath: globalStorageURL.path(percentEncoded: false),
            sphereStoragePath: sphereStorageURL.path(percentEncoded: false),
            gatewayURL: gatewayURL?.absoluteString
        )
        self._noosphere = noosphere
        return noosphere
    }
    
    /// Get or open default Sphere.
    private func sphere() throws -> SphereFS {
        if let sphere = self._sphere {
            return sphere
        }
        guard let identity = self._sphereIdentity else {
            throw NoosphereServiceError.defaultSphereNotFound
        }
        let noosphere = try noosphere()
        let sphere = try SphereFS(
            noosphere: noosphere,
            identity: identity
        )
        self._sphere = sphere
        return sphere
    }
    
    func identity() throws -> String {
        try self.sphere().identity
    }

    func version() throws -> String {
        try self.sphere().version()
    }
    
    func getFileVersion(slashlink: String) -> String? {
        try? self.sphere().getFileVersion(slashlink: slashlink)
    }
    
    func readHeaderValueFirst(slashlink: String, name: String) -> String? {
        try? self.sphere().readHeaderValueFirst(
            slashlink: slashlink,
            name: name
        )
    }
    
    func readHeaderNames(slashlink: String) -> [String] {
        guard let names = try? self.sphere().readHeaderNames(
            slashlink: slashlink
        ) else {
            return []
        }
        return names
    }
    
    func read(slashlink: String) throws -> MemoData {
        try self.sphere().read(slashlink: slashlink)
    }
    
    func write(
        slug: String,
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
    
    func remove(slug: String) throws {
        try self.sphere().remove(slug: slug)
    }
    
    @discardableResult func save() throws -> String {
        try self.sphere().save()
    }
    
    func list() throws -> [String] {
        try self.sphere().list()
    }
    
    func sync() throws -> String {
        try self.sphere().sync()
    }
    
    func changes(_ since: String?) throws -> [String] {
        try self.sphere().changes(since)
    }
}
