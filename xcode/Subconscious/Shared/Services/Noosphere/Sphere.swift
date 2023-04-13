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

/// Describes a Sphere.
/// See `Sphere` for a concrete implementation.
public protocol SphereProtocol {
    associatedtype Memo
    
    func version() throws -> String
    
    func getFileVersion(slashlink: Slashlink) -> String?
    
    func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) -> String?
    
    func readHeaderNames(slashlink: Slashlink) -> [String]
    
    func read(slashlink: Slashlink) throws -> Memo
    
    func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) throws
    
    func remove(slug: Slug) throws
    
    func save() throws -> String
    
    func list() throws -> [Slug]
    
    func sync() throws -> String
    
    func changes(_ since: String?) throws -> [Slug]
    
    func getPetname(petname: Petname) throws -> String
    
    func setPetname(did: String?, petname: Petname) throws
        
    func resolvePetname(petname: Petname) throws -> String
    
    func listPetnames() throws -> [Petname]
    
    func getPetnameChanges(sinceCid: String) throws -> [Petname]
    
    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    func traverse(petname: Petname) throws -> Sphere
}

/// Describes a Sphere using a Combine Publisher-based API.
/// See `Sphere` for concrete implementation.
public protocol SpherePublisherProtocol {
    associatedtype Memo
    
    func versionFuture() -> Future<String, Error>
    
    func getFileVersionFuture(
        slashlink: Slashlink
    ) -> Future<String?, Never>
    
    func readHeaderValueFirstFuture(
        slashlink: Slashlink,
        name: String
    ) -> Future<String?, Never>
    
    func readHeaderNamesFuture(
        slashlink: Slashlink
    ) -> Future<[String], Never>
    
    func readFuture(slashlink: Slashlink) -> Future<Memo, Error>
    
    func writeFuture(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) -> Future<Void, Error>
    
    func removeFuture(slug: Slug) -> Future<Void, Error>
    
    func saveFuture() -> Future<String, Error>
    
    func listFuture() -> Future<[Slug], Error>
    
    func syncFuture() -> Future<String, Error>
    
    func changesFuture(_ since: String?) -> Future<[Slug], Error>
    
    func getPetnameFuture(petname: Petname) -> Future<String, Error>
    
    func setPetnameFuture(
        did: String?,
        petname: Petname
    ) -> Future<Void, Error>
    
    func resolvePetnameFuture(petname: Petname) -> Future<String, Error>
    
    func listPetnamesFuture() -> Future<[Petname], Error>
    
    func getPetnameChangesFuture(
        sinceCid: String
    ) -> Future<[Petname], Error>
    
    /// Attempt to retrieve the sphere of a recorded petname, this can
    /// be chained to walk over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    func traverseFuture(petname: Petname) -> Future<Sphere, Error>
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
public final class Sphere: SphereProtocol, SpherePublisherProtocol {
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "Sphere"
    )
    private let noosphere: Noosphere
    public let sphere: OpaquePointer
    public let identity: String
    
    private var queue: DispatchQueue {
        noosphere.queue
    }

    private init(noosphere: Noosphere, sphere: OpaquePointer, identity: String) {
        self.noosphere = noosphere
        self.sphere = sphere
        self.identity = identity
    }
    
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self.identity = identity
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
    
    /// Get current version of sphere synchronously
    public func version() throws -> String {
        guard let sphereVersionPointer = try Noosphere.callWithError(
            ns_sphere_version_get,
            noosphere.noosphere,
            identity
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(sphereVersionPointer)
        }
        return String.init(cString: sphereVersionPointer)
    }
    
    /// Get current version of sphere as a future
    public func versionFuture() -> Future<String, Error> {
        queue.future {
            try self.version()
        }
    }

    /// Read first header value for memo at slashlink
    /// - Returns: value, if any
    public func readHeaderValueFirst(
        slashlink: Slashlink,
        name: String
    ) -> String? {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_content_read,
            noosphere.noosphere,
            sphere,
            slashlink.description
        ) else {
            return nil
        }
        defer {
            ns_sphere_file_free(file)
        }
        return Self.readFileHeaderValueFirst(
            file: file,
            name: name
        )
    }
    
    /// Read first header value for memo at slashlink
    /// - Returns: Future for value, if any
    public func readHeaderValueFirstFuture(
        slashlink: Slashlink,
        name: String
    ) -> Future<String?, Never> {
        queue.future {
            self.readHeaderValueFirst(slashlink: slashlink, name: name)
        }
    }

    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    /// - Returns CID string, if any
    public func getFileVersion(slashlink: Slashlink) -> String? {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_content_read,
            noosphere.noosphere,
            sphere,
            slashlink.description
        ) else {
            return nil
        }
        guard let cid = try? Noosphere.callWithError(
            ns_sphere_file_version_get,
            file
        ) else {
            return nil
        }
        defer {
            ns_string_free(cid)
        }
        return String.init(cString: cid)
    }
    
    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    /// - Returns Future for CID string, if any
    public func getFileVersionFuture(
        slashlink: Slashlink
    ) -> Future<String?, Never> {
        queue.future {
            self.getFileVersion(slashlink: slashlink)
        }
    }
    
    /// Read all header names for a given slashlink.
    /// - Returns array of header name strings.
    public func readHeaderNames(slashlink: Slashlink) -> [String] {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_content_read,
            noosphere.noosphere,
            sphere,
            slashlink.description
        ) else {
            return []
        }
        defer {
            ns_sphere_file_free(file)
        }
        return Self.readFileHeaderNames(file: file)
    }
    
    /// Read all header names for a given slashlink.
    /// - Returns `Future` for array of header name strings.
    public func readHeaderNamesFuture(
        slashlink: Slashlink
    ) -> Future<[String], Never> {
        queue.future {
            self.readHeaderNames(slashlink: slashlink)
        }
    }
    
    /// Read the value of a memo from this, or another sphere
    /// - Returns: `MemoData`
    public func read(slashlink: Slashlink) throws -> MemoData {
        guard let file = try Noosphere.callWithError(
            ns_sphere_content_read,
            noosphere.noosphere,
            sphere,
            slashlink.markup
        ) else {
            throw SphereError.fileDoesNotExist(slashlink.description)
        }
        defer {
            ns_sphere_file_free(file)
        }
        
        guard let contentType = Self.readFileHeaderValueFirst(
            file: file,
            name: "Content-Type"
        ) else {
            throw SphereError.contentTypeMissing(slashlink.description)
        }
        
        let bodyRaw = try Noosphere.callWithError(
            ns_sphere_file_contents_read,
            noosphere.noosphere,
            file
        )
        defer {
            ns_bytes_free(bodyRaw)
        }
        let body = Data(bytes: bodyRaw.ptr, count: bodyRaw.len)
        
        var headers: [Header] = []
        let headerNames = Self.readFileHeaderNames(file: file)
        for name in headerNames {
            // Skip content type. We've already retreived it.
            guard name != "Content-Type" else {
                continue
            }
            guard let value = Self.readFileHeaderValueFirst(
                file: file,
                name: name
            ) else {
                continue
            }
            headers.append(Header(name: name, value: value))
        }
        
        return MemoData(
            contentType: contentType,
            additionalHeaders: headers,
            body: body
        )
    }
    
    /// Read the value of a memo from this, or another sphere
    /// - Returns: `Future` for `MemoData`
    public func readFuture(slashlink: Slashlink) -> Future<MemoData, Error> {
        queue.future {
            try self.read(slashlink: slashlink)
        }
    }

    /// Write to sphere
    private func _write(
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
    public func write(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) throws {
        try queue.sync {
            try self._write(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }
    }
    
    /// Write to sphere
    /// - Returns Future for Void (success), or error
    public func writeFuture(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) -> Future<Void, Error> {
        queue.future {
            try self._write(
                slug: slug,
                contentType: contentType,
                additionalHeaders: additionalHeaders,
                body: body
            )
        }
    }
    
    /// Get the sphere identity as a DID that the given petname is assigned to
    /// in the sphere.
    ///
    /// This call will produce an error if the petname has not been assigned to
    /// a sphere identity (or was previously assigned to a sphere identity
    /// but has since been unassigned).
    /// - Returns DID string
    public func getPetname(petname: Petname) throws -> String {
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
        
        return String(cString: name)
    }
    
    /// Get the sphere identity as a DID that the given petname is assigned to
    /// in the sphere.
    ///
    /// This call will produce an error if the petname has not been assigned to
    /// a sphere identity (or was previously assigned to a sphere identity
    /// but has since been unassigned).
    /// - Returns `Future` for DID string
    public func getPetnameFuture(petname: Petname) -> Future<String, Error> {
        queue.future {
            try self.getPetname(petname: petname)
        }
    }
    
    /// Set petname for DID
    private func _setPetname(did: String?, petname: Petname) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            sphere,
            petname.description,
            did
        )
    }
    
    /// Set petname for DID
    public func setPetname(did: String?, petname: Petname) throws {
        try queue.sync {
            try _setPetname(did: did, petname: petname)
        }
    }
    
    /// Set petname for DID
    /// - Returns Future for Void (success), or error
    public func setPetnameFuture(
        did: String?,
        petname: Petname
    ) -> Future<Void, Error> {
        queue.future {
            try self._setPetname(did: did, petname: petname)
        }
    }
    
    /// Resolve DID for petname
    public func resolvePetname(petname: Petname) throws -> String {
        let did = try Noosphere.callWithError(
            ns_sphere_petname_resolve,
            noosphere.noosphere,
            sphere,
            petname.description
        )
        
        guard let did = did else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(did)
        }
        
        return String(cString: did)
    }
    
    /// Resolve DID for petname
    public func resolvePetnameFuture(
        petname: Petname
    ) -> Future<String, Error> {
        queue.future {
            try self.resolvePetname(petname: petname)
        }
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
    /// - Returns an a Future for an array of `Petname`
    public func listPetnamesFuture() -> Future<[Petname], Error> {
        queue.future {
            try self.listPetnames()
        }
    }
    
    /// Get all petname changes since a CID. Returned petnames were changed
    /// in some way. It is up to you to read them to find out what happend
    /// (deletion, update, etc).
    /// - Returns an array of `Petname`
    public func getPetnameChanges(sinceCid: String) throws -> [Petname] {
        let changes = try Noosphere.callWithError(
            ns_sphere_petname_changes,
            noosphere.noosphere,
            sphere,
            sinceCid
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
    
    public func getPetnameChangesFuture(sinceCid: String) -> Future<[Petname], Error> {
        queue.future {
            try self.getPetnameChanges(sinceCid: sinceCid)
        }
    }

    public func traverse(petname: Petname) throws -> Sphere {
        let identity = try self.getPetname(petname: petname)
        
        let sphere = try Noosphere.callWithError(
            ns_sphere_traverse_by_petname,
            noosphere.noosphere,
            sphere,
            petname.description
        )
        
        guard let sphere = sphere else {
            throw NoosphereError.foreignError("ns_sphere_traverse_by_petname failed to find sphere")
        }
        
        return Sphere(noosphere: noosphere, sphere: sphere, identity: identity)
    }
    
    public func traverseFuture(petname: Petname) -> Future<Sphere, Error> {
        queue.future {
            try self.traverse(petname: petname)
        }
    }
    
    /// Save outstanding writes and return new Sphere version
    private func _save() throws -> String {
        try Noosphere.callWithError(
            ns_sphere_save,
            noosphere.noosphere,
            sphere,
            nil
        )
        return try self.version()
    }

    /// Save outstanding writes and return new Sphere version
    /// This method is called on the write queue, and is synchronous!
    /// Use `.saveFuture` instead if you are on the main thread.
    /// - Returns a version CID string
    @discardableResult public func save() throws -> String {
        try queue.sync {
            try _save()
        }
    }
    
    /// Save outstanding writes and return new Sphere version
    /// This method is called on the write queue, and is asynchronous.
    /// - Returns a `Future` for version CID string, or error.
    public func saveFuture() -> Future<String, Error> {
        queue.future {
            try self._save()
        }
    }
    
    /// Remove slug from sphere
    private func _remove(slug: Slug) throws {
        try Noosphere.callWithError(
            ns_sphere_content_remove,
            noosphere.noosphere,
            sphere,
            slug.description
        )
    }
    
    /// Remove slug from sphere.
    /// This method is called on the write queue, and is synchronous!
    /// Use `.removeFuture` instead if you are on the main thread.
    public func remove(slug: Slug) throws {
        try queue.sync {
            try self._remove(slug: slug)
        }
    }
    
    /// This method is called on the write queue, and is asynchronous.
    /// - Returns a `Future` for Void (success) or error.
    public func removeFuture(slug: Slug) -> Future<Void, Error> {
        queue.future {
            try self._remove(slug: slug)
        }
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
    /// - Returns a `Future` for an array of `Slug`, or error.
    public func listFuture() -> Future<[Slug], Error> {
        queue.future {
            try self.list()
        }
    }

    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    private func _sync() throws -> String {
        let versionPointer = try Noosphere.callWithError(
            ns_sphere_sync,
            noosphere.noosphere,
            identity
        )
        guard let versionPointer = versionPointer else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(versionPointer)
        }
        return String(cString: versionPointer)
    }
    
    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    /// This method runs on the write queue and is synchronous!
    /// Use `.syncFuture` instead if on the main thread.
    /// - Returns a CID string for the new sphere version.
    public func sync() throws -> String {
        try queue.sync {
            try self._sync()
        }
    }
    
    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    /// This method runs on the write queue and is asynchronous.
    /// - Returns a `Future` CID string for the new sphere version.
    public func syncFuture() -> Future<String, Error> {
        queue.future {
            try self._sync()
        }
    }

    /// List all changed slugs between two versions of a sphere.
    /// This method lists which slugs changed between version, but not
    /// what changed.
    public func changes(_ since: String? = nil) throws -> [Slug] {
        let changes = try Noosphere.callWithError(
            ns_sphere_content_changes,
            noosphere.noosphere,
            sphere,
            since
        )
        defer {
            ns_string_array_free(changes)
        }
        
        return try changes.toStringArray().map({ string in
            try Slug(string).unwrap(SphereError.parseError(string))
        })
    }
    
    public func changesFuture(_ since: String?) -> Future<[Slug], Error> {
        queue.future {
            try self.changes(since)
        }
    }
    
    deinit {
        ns_sphere_free(sphere)
        logger.debug("deinit with identity \(self.identity)")
    }
    
    /// Read first header value for file pointer
    static func readFileHeaderValueFirst(
        file: OpaquePointer,
        name: String
    ) -> String? {
        guard let valueRaw = ns_sphere_file_header_value_first(
            file,
            name
        ) else {
            return nil
        }
        defer {
            ns_string_free(valueRaw)
        }
        return String(cString: valueRaw)
    }

    /// Get all header names for a given file pointer
    static func readFileHeaderNames(
        file: OpaquePointer
    ) -> [String] {
        let file_header_names = ns_sphere_file_header_names_read(file)
        defer {
            ns_string_array_free(file_header_names)
        }

        return file_header_names.toStringArray()
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
