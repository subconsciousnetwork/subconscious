//
//  Sphere.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/13/23.
//

import Foundation
import Combine
import SwiftNoosphere
import os

public typealias Cid = String

/// Describes a Sphere.
/// See `Sphere` for a concrete implementation.
public protocol SphereProtocol {
    func identity() async throws -> Did
    
    func version() async throws -> Cid
    
    func getFileVersion(slashlink: Slashlink) async -> Cid?
    
    func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) async -> String?
    
    func readHeaderNames(slashlink: Slashlink) async -> [String]
    
    func read(slashlink: Slashlink) async throws -> MemoData
    
    func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) async throws
    
    func remove(slug: Slug) async throws
    
    func save() async throws -> Cid
    
    func list() async throws -> [Slug]
    
    func sync() async throws -> Cid
    
    func changes(since: Cid?) async throws -> [Slug]
    
    func getPetname(petname: Petname) async throws -> Did
    
    func setPetname(did: Did?, petname: Petname) async throws
        
    func resolvePetname(petname: Petname) async throws -> Cid
    
    func listPetnames() async throws -> [Petname]
    
    func getPetnameChanges(since: Cid) async throws -> [Petname]
    
    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    func traverse(petname: Petname) async throws -> Sphere
}

extension SphereProtocol {
    /// Resolve a relative slashlink, making it an absolute slashlink.
    /// - Returns Slashlink with did peer
    func resolve(slashlink: Slashlink) async throws -> Slashlink {
        switch slashlink.peer {
        case .did:
            return slashlink
        case .petname(let petname):
            // Get did for petname
            let did = try await Func.run {
                // Look locally if we have the option
                if petname.parts.count == 1 {
                    return try await self.getPetname(petname: petname.root.toPetname())
                }
                
                let sphere = try await self.traverse(petname: petname)
                return try await sphere.identity()
            }
            
            // Return new slashlink with did root
            return Slashlink(
                peer: .did(did),
                slug: slashlink.slug
            )
        case .none:
            let identity = try await self.identity()
            return Slashlink(
                peer: Peer.did(identity),
                slug: slashlink.slug
            )
        }
    }
}

/// Describes a Sphere using a Combine Publisher-based API.
/// See `Sphere` for concrete implementation.
public protocol SpherePublisherProtocol {
    associatedtype Memo
    
    func identityPublisher() -> AnyPublisher<Did, Error>
    
    func versionPublisher() -> AnyPublisher<Cid, Error>
    
    func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<Cid?, Never>
    
    func readHeaderValueFirstPublisher(
        slashlink: Slashlink,
        name: String
    ) -> AnyPublisher<String?, Never>
    
    func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never>
    
    func readPublisher(slashlink: Slashlink) -> AnyPublisher<Memo, Error>
    
    func writePublisher(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) -> AnyPublisher<Void, Error>
    
    func removePublisher(slug: Slug) -> AnyPublisher<Void, Error>
    
    func savePublisher() -> AnyPublisher<Cid, Error>
    
    func listPublisher() -> AnyPublisher<[Slug], Error>
    
    func syncPublisher() -> AnyPublisher<Cid, Error>
    
    func changesPublisher(since: Cid?) -> AnyPublisher<[Slug], Error>
    
    func getPetnamePublisher(petname: Petname) -> AnyPublisher<Did, Error>
    
    func setPetnamePublisher(
        did: Did?,
        petname: Petname
    ) -> AnyPublisher<Void, Error>
    
    func resolvePetnamePublisher(petname: Petname) -> AnyPublisher<Cid, Error>
    
    func listPetnamesPublisher() -> AnyPublisher<[Petname], Error>
    
    func getPetnameChangesPublisher(
        since: Cid
    ) -> AnyPublisher<[Petname], Error>
    
    /// Attempt to retrieve the sphere of a recorded petname, this can
    /// be chained to walk over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    func traversePublisher(petname: Petname) -> AnyPublisher<Sphere, Error>
}

enum SphereError: Error, LocalizedError {
    case contentTypeMissing(_ slashlink: String)
    case fileDoesNotExist(_ slashlink: String)
    case parseError(_ message: String)
    
    var errorDescription: String? {
        switch self {
        case .contentTypeMissing(let slashlink):
            return "Content-Type header is missing for file: \(slashlink)"
        case .fileDoesNotExist(let slashlink):
            return "File does not exist: \(slashlink)"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}

/// Sphere file system access.
/// Provides sphere file system methods and manages lifetime of sphere pointer.
public actor Sphere: SphereProtocol, SpherePublisherProtocol {
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "Sphere"
    )
    private let noosphere: Noosphere
    public let sphere: OpaquePointer
    private let _identity: String
    
    /// Initialize a sphere from an already-created sphere pointer, retrieving
    /// identity from Noosphere.
    ///
    /// This is a private initializer used in implementing traversal.
    private init(
        noosphere: Noosphere,
        sphere: OpaquePointer?
    ) throws {
        guard let sphere = sphere else {
            throw NoosphereError.nullPointer
        }
        guard let identityPointer = try Noosphere.callWithError(
            ns_sphere_identity,
            noosphere.noosphere,
            sphere
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(identityPointer)
        }
        let identity = String(cString: identityPointer)
        self.noosphere = noosphere
        self._identity = identity
        self.sphere = sphere
        logger.debug("init from pointer with identity: \(identity)")
    }

    /// Initializer
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self._identity = identity
        guard let fs = try Noosphere.callWithError(
            ns_sphere_open,
            noosphere.noosphere,
            identity
        ) else {
            throw NoosphereError.nullPointer
        }
        self.sphere = fs
        logger.debug("init with identity: \(identity)")
    }
    
    /// Get Did for sphere
    public func identity() throws -> Did {
        let identity = self._identity
        return try Did(identity).unwrap(
            CodingError.decodingError(
                message: "Could not decode did: \(identity)"
            )
        )
    }

    nonisolated public func identityPublisher() -> AnyPublisher<Did, Error> {
        Future.detached {
            try await self.identity()
        }
        .eraseToAnyPublisher()
    }

    /// Get current version of sphere
    public func version() throws -> Cid {
        guard let sphereVersionPointer = try Noosphere.callWithError(
            ns_sphere_version,
            noosphere.noosphere,
            sphere
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(sphereVersionPointer)
        }
        return String.init(cString: sphereVersionPointer)
    }
    
    /// Get current version of sphere as a publisher
    nonisolated public func versionPublisher() -> AnyPublisher<Cid, Error> {
        Future.detached {
            try await self.version()
        }
        .eraseToAnyPublisher()
    }
    
    /// Open sphere file from a slashlink.
    /// - Returns a SphereFile
    func readFile(slashlink: Slashlink) async throws -> SphereFile {
        try await withCheckedThrowingContinuation { continuation in
            SwiftNoosphere.nsSphereContentRead(
                self.noosphere.noosphere,
                sphere,
                slashlink.description
            ) { error, pointer in
                if let message = Noosphere.readErrorMessage(error) {
                    continuation.resume(
                        throwing: NoosphereError.foreignError(message)
                    )
                    return
                }
                guard let file = SphereFile(
                    noosphere: self.noosphere,
                    file: pointer
                ) else {
                    continuation.resume(throwing: NoosphereError.nullPointer)
                    return
                }
                continuation.resume(returning: file)
                return
            }
        }
    }

    /// Read first header value for memo at slashlink
    /// - Returns: value, if any
    public func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) async -> String? {
        guard let file = try? await readFile(slashlink: slashlink) else {
            return nil
        }
        return try? await file.readHeaderValueFirst(name: name)
    }
    
    /// Read first header value for memo at slashlink
    /// - Returns: `AnyPublisher` for value, if any
    nonisolated public func readHeaderValueFirstPublisher(
        slashlink: Slashlink,
        name: String
    ) -> AnyPublisher<String?, Never> {
        Future.detached {
            await self.readHeaderValueFirst(slashlink: slashlink, name: name)
        }
        .eraseToAnyPublisher()
    }

    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    /// - Returns CID string, if any
    public func getFileVersion(slashlink: Slashlink) async -> Cid? {
        guard let file = try? await readFile(slashlink: slashlink) else {
            return nil
        }
        return try? await file.version()
    }
    
    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    /// - Returns `AnyPublisher` for CID string, if any
    nonisolated public func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<Cid?, Never> {
        Future.detached {
            await self.getFileVersion(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }
    
    /// Read all header names for a given slashlink.
    /// - Returns array of header name strings.
    public func readHeaderNames(slashlink: Slashlink) async -> [String] {
        guard let file = try? await readFile(slashlink: slashlink) else {
            return []
        }
        guard let names = try? await file.readHeaderNames() else {
            return []
        }
        return names
    }
    
    /// Read all header names for a given slashlink.
    /// - Returns `AnyPublisher` for array of header name strings.
    nonisolated public func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never> {
        Future.detached {
            await self.readHeaderNames(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }

    /// Read the value of a memo from this, or another sphere
    /// - Returns: `MemoData`
    public func read(slashlink: Slashlink) async throws -> MemoData {
        let file = try await readFile(slashlink: slashlink)

        guard let contentType = try? await file.readHeaderValueFirst(
            name: "Content-Type"
        ) else {
            throw SphereError.contentTypeMissing(slashlink.description)
        }

        var headers: [Header] = []
        let headerNames = try await file.readHeaderNames()
        for name in headerNames {
            // Skip content type. We've already retreived it.
            guard name != "Content-Type" else {
                continue
            }
            guard let value = try await file.readHeaderValueFirst(
                name: name
            ) else {
                continue
            }
            headers.append(Header(name: name, value: value))
        }
        
        let contents = try await file.consumeContents()

        return MemoData(
            contentType: contentType,
            additionalHeaders: headers,
            body: contents
        )
    }
    
    /// Read the value of a memo from this, or another sphere
    /// - Returns: `AnyPublisher` for `MemoData`
    nonisolated public func readPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<MemoData, Error> {
        Future.detached {
            try await self.read(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
    }

    /// Write to sphere
    public func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header] = [],
        body: Data
    ) throws {
        try body.withUnsafeBytes({ rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            let pointer = bufferPointer.baseAddress!
            let bodyRaw = slice_ref_uint8(
                ptr: pointer, len: body.count
            )
            
            guard let additionalHeadersContainer = ns_headers_create() else {
                throw NoosphereError.foreignError("ns_headers_create failed to return pointer")
            }
            defer {
                ns_headers_free(additionalHeadersContainer)
            }
            
            for header in additionalHeaders {
                ns_headers_add(
                    additionalHeadersContainer,
                    header.name,
                    header.value
                )
            }
            
            try Noosphere.callWithError { error in
                ns_sphere_content_write(
                    noosphere.noosphere,
                    sphere,
                    slug.description,
                    contentType,
                    bodyRaw,
                    additionalHeadersContainer,
                    error
                )
            }
        })
    }
    
    /// Write to sphere
    /// - Returns `AnyPublisher` for Void (success), or error
    nonisolated public func writePublisher(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header] = [],
        body: Data
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.write(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }
        .eraseToAnyPublisher()
    }
    
    /// Get the sphere identity as a DID that the given petname is assigned to
    /// in the sphere.
    ///
    /// This call will produce an error if the petname has not been assigned to
    /// a sphere identity (or was previously assigned to a sphere identity
    /// but has since been unassigned).
    /// - Returns DID string
    public func getPetname(petname: Petname) throws -> Did {
        let name = try Noosphere.callWithError(
            ns_sphere_petname_get,
            noosphere.noosphere,
            sphere,
            petname.description
        )
        
        guard let name = name else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(name)
        }
        
        let string = String(cString: name)
        
        return try Did(string).unwrap(
            CodingError.decodingError(
                message: "Could not decode did: \(string)"
            )
        )
    }
    
    /// Get the sphere identity as a DID that the given petname is assigned to
    /// in the sphere.
    ///
    /// This call will produce an error if the petname has not been assigned to
    /// a sphere identity (or was previously assigned to a sphere identity
    /// but has since been unassigned).
    /// - Returns `AnyPublisher` for DID string
    nonisolated public func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Did, Error> {
        Future.detached {
            try await self.getPetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Set petname for DID
    public func setPetname(did: Did?, petname: Petname) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            sphere,
            petname.description,
            did?.description
        )
    }
        
    /// Set petname for DID
    /// - Returns `AnyPublisher` for Void (success), or error
    nonisolated public func setPetnamePublisher(
        did: Did?,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Resolve a configured petname.
    ///
    /// Uses the sphere identity that the petname is assigned to and determining
    /// a link - a CID - that is associated with it. The returned
    /// link is a UTF-8, base64-encoded CIDv1 string that may be used to resolve
    /// data from the IPFS content space. Note that this call will produce an error
    /// if no address has been assigned to the given petname.
    ///
    /// - Returns a `Cid`
    public func resolvePetname(petname: Petname) throws -> Cid {
        let cid = try Noosphere.callWithError(
            ns_sphere_petname_resolve,
            noosphere.noosphere,
            sphere,
            petname.description
        )
        
        guard let cid = cid else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(cid)
        }
        
        return String(cString: cid)
    }
    
    /// Resolve DID for petname
    /// - Returns `AnyPublisher` for DID string
    nonisolated public func resolvePetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<Cid, Error> {
        Future.detached {
            try await self.resolvePetname(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// List all petnames in user's follows (address book)
    /// - Returns an a array of `Petname`
    public func listPetnames() throws -> [Petname] {
        let petnames = try Noosphere.callWithError(
            ns_sphere_petname_list,
            noosphere.noosphere,
            sphere
        )
        
        defer {
            ns_string_array_free(petnames)
        }
        
        return try petnames.toStringArray().map({ string in
            try Petname(string).unwrap(
                SphereError.parseError(string)
            )
        })
    }
    
    /// List all petnames in user's follows (address book)
    /// - Returns an a `AnyPublisher` for an array of `Petname`
    nonisolated public func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        Future.detached {
            try await self.listPetnames()
        }
        .eraseToAnyPublisher()
    }
    
    /// Get all petname changes since a CID. Returned petnames were changed
    /// in some way. It is up to you to read them to find out what happend
    /// (deletion, update, etc).
    /// - Returns an array of `Petname`
    public func getPetnameChanges(since cid: Cid) throws -> [Petname] {
        let changes = try Noosphere.callWithError(
            ns_sphere_petname_changes,
            noosphere.noosphere,
            sphere,
            cid
        )
        defer {
            ns_string_array_free(changes)
        }
        
        return try changes.toStringArray().map({ string in
            try Petname(string).unwrap(
                SphereError.parseError(string)
            )
        })
    }
    
    /// Get all petname changes since a CID. Returned petnames were changed
    /// in some way. It is up to you to read them to find out what happend
    /// (deletion, update, etc).
    /// - Returns an `AnyPublisher` for array of `Petname`
    nonisolated public func getPetnameChangesPublisher(
        since cid: Cid
    ) -> AnyPublisher<[Petname], Error> {
        Future.detached {
            try await self.getPetnameChanges(since: cid)
        }
        .eraseToAnyPublisher()
    }

    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    /// - Returns a sphere
    public func traverse(petname: Petname) async throws -> Sphere {
        try await withCheckedThrowingContinuation { continuation in
            nsSphereTraverseByPetname(
                self.noosphere.noosphere,
                self.sphere,
                petname.verbatim
            ) { error, pointer in
                if let error = Noosphere.readErrorMessage(error) {
                    continuation.resume(
                        throwing: NoosphereError.foreignError(error)
                    )
                    return
                }
                guard let pointer = pointer else {
                    continuation.resume(throwing: NoosphereError.nullPointer)
                    return
                }
                do {
                    let sphere = try Sphere(
                        noosphere: self.noosphere,
                        sphere: pointer
                    )
                    continuation.resume(
                        returning: sphere
                    )
                    return
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
            }
        }
    }
    
    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres.
    /// - Returns an `AnyPublisher` for  sphere
    nonisolated public func traversePublisher(
        petname: Petname
    ) -> AnyPublisher<Sphere, Error> {
        Future.detached {
            try await self.traverse(petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Save outstanding writes and return new Sphere version
    /// This method is called on the write queue, and is synchronous!
    /// Use `.savePublisher` instead if you are on the main thread.
    /// - Returns a version CID string
    @discardableResult public func save() throws -> Cid {
        try Noosphere.callWithError(
            ns_sphere_save,
            noosphere.noosphere,
            sphere,
            nil
        )
        return try self.version()
    }

    /// Save outstanding writes and return new Sphere version
    /// This method is called on the write queue, and is asynchronous.
    /// - Returns a `AnyPublisher` for version CID string, or error.
    nonisolated public func savePublisher() -> AnyPublisher<Cid, Error> {
        Future.detached {
            try await self.save()
        }
        .eraseToAnyPublisher()
    }
    
    /// Remove slug from sphere.
    public func remove(slug: Slug) throws {
        try Noosphere.callWithError(
            ns_sphere_content_remove,
            noosphere.noosphere,
            sphere,
            slug.description
        )
    }
    
    /// Remove slug from sphere.
    /// - Returns a `AnyPublisher` for Void (success) or error.
    nonisolated public func removePublisher(slug: Slug) -> AnyPublisher<Void, Error> {
        Future.detached {
            try await self.remove(slug: slug)
        }
        .eraseToAnyPublisher()
    }
    
    /// List all slugs in sphere
    /// - Returns an array of `Slug`
    public func list() throws -> [Slug] {
        let slugs = try Noosphere.callWithError(
            ns_sphere_content_list,
            noosphere.noosphere,
            sphere
        )
        defer {
            ns_string_array_free(slugs)
        }
        
        return try slugs.toStringArray().map({ string in
            try Slug(string).unwrap(SphereError.parseError(string))
        })
    }
    
    /// List all slugs in sphere.
    /// - Returns a `AnyPublisher` for an array of `Slug`, or error.
    nonisolated public func listPublisher() -> AnyPublisher<[Slug], Error> {
        Future.detached {
            try await self.list()
        }
        .eraseToAnyPublisher()
    }

    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    /// - Returns a CID string for the new sphere version.
    public func sync() async throws -> Cid {
        try await withCheckedThrowingContinuation { continuation in
            nsSphereSync(
                noosphere.noosphere,
                self.sphere
            ) { error, version in
                if let error = Noosphere.readErrorMessage(error) {
                    continuation.resume(
                        throwing: NoosphereError.foreignError(error)
                    )
                    return
                }
                guard let version = Noosphere.readString(version) else {
                    continuation.resume(throwing: NoosphereError.nullPointer)
                    return
                }
                continuation.resume(returning: version)
                return
            }
        }
    }
    
    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    /// This method runs on the write queue and is asynchronous.
    /// - Returns a `AnyPublisher` CID string for the new sphere version.
    nonisolated public func syncPublisher() -> AnyPublisher<Cid, Error> {
        Future.detached {
            try await self.sync()
        }
        .eraseToAnyPublisher()
    }

    /// List all changed slugs between two versions of a sphere.
    /// This method lists which slugs changed between version, but not
    /// what changed.
    /// - Returns array of `Slug`
    public func changes(since cid: Cid? = nil) throws -> [Slug] {
        let changes = try Noosphere.callWithError(
            ns_sphere_content_changes,
            noosphere.noosphere,
            sphere,
            cid
        )
        defer {
            ns_string_array_free(changes)
        }
        
        return try changes.toStringArray().map({ string in
            try Slug(string).unwrap(SphereError.parseError(string))
        })
    }
    
    /// List all changed slugs between two versions of a sphere.
    /// This method lists which slugs changed between version, but not
    /// what changed.
    /// - Returns `AnyPublisher` for array of `Slug`
    nonisolated public func changesPublisher(
        since cid: String?
    ) -> AnyPublisher<[Slug], Error> {
        Future.detached {
            try await self.changes(since: cid)
        }
        .eraseToAnyPublisher()
    }
    
    deinit {
        ns_sphere_free(sphere)
        let identity = self._identity
        logger.debug("deinit with identity \(identity)")
    }
}

extension slice_boxed_char_ptr_t {
    func toStringArray() -> [String] {
        let count = self.len
        guard var pointer = self.ptr else {
            return []
        }

        var result: [String] = []
        for _ in 0..<count {
            let item = String(cString: pointer.pointee!)
            result.append(item)
            pointer += 1;
        }
        return result
    }
}
