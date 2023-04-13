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
    
    func versionPublisher() -> AnyPublisher<String, Error>
    
    func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<String?, Never>
    
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
    
    func savePublisher() -> AnyPublisher<String, Error>
    
    func listPublisher() -> AnyPublisher<[Slug], Error>
    
    func syncPublisher() -> AnyPublisher<String, Error>
    
    func changesPublisher(_ since: String?) -> AnyPublisher<[Slug], Error>
    
    func getPetnamePublisher(petname: Petname) -> AnyPublisher<String, Error>
    
    func setPetnamePublisher(
        did: String?,
        petname: Petname
    ) -> AnyPublisher<Void, Error>
    
    func resolvePetnamePublisher(petname: Petname) -> AnyPublisher<String, Error>
    
    func listPetnamesPublisher() -> AnyPublisher<[Petname], Error>
    
    func getPetnameChangesPublisher(
        sinceCid: String
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
    
    /// Get current version of sphere as a publisher
    public func versionPublisher() -> AnyPublisher<String, Error> {
        queue.future {
            try self.version()
        }
        .eraseToAnyPublisher()
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
    /// - Returns: `AnyPublisher` for value, if any
    public func readHeaderValueFirstPublisher(
        slashlink: Slashlink,
        name: String
    ) -> AnyPublisher<String?, Never> {
        queue.future {
            self.readHeaderValueFirst(slashlink: slashlink, name: name)
        }
        .eraseToAnyPublisher()
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
    /// - Returns `AnyPublisher` for CID string, if any
    public func getFileVersionPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<String?, Never> {
        queue.future {
            self.getFileVersion(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
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
    /// - Returns `AnyPublisher` for array of header name strings.
    public func readHeaderNamesPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<[String], Never> {
        queue.future {
            self.readHeaderNames(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
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
    /// - Returns: `AnyPublisher` for `MemoData`
    public func readPublisher(
        slashlink: Slashlink
    ) -> AnyPublisher<MemoData, Error> {
        queue.future {
            try self.read(slashlink: slashlink)
        }
        .eraseToAnyPublisher()
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
        additionalHeaders: [Header] = [],
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
    /// - Returns `AnyPublisher` for Void (success), or error
    public func writePublisher(
        slug: Slug,
        contentType: String,
        additionalHeaders: [Header] = [],
        body: Data
    ) -> AnyPublisher<Void, Error> {
        queue.future {
            try self._write(
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
    /// - Returns `AnyPublisher` for DID string
    public func getPetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<String, Error> {
        queue.future {
            try self.getPetname(petname: petname)
        }
        .eraseToAnyPublisher()
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
    /// - Returns `AnyPublisher` for Void (success), or error
    public func setPetnamePublisher(
        did: String?,
        petname: Petname
    ) -> AnyPublisher<Void, Error> {
        queue.future {
            try self._setPetname(did: did, petname: petname)
        }
        .eraseToAnyPublisher()
    }
    
    /// Resolve DID for petname
    /// - Returns DID string
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
    /// - Returns `AnyPublisher` for DID string
    public func resolvePetnamePublisher(
        petname: Petname
    ) -> AnyPublisher<String, Error> {
        queue.future {
            try self.resolvePetname(petname: petname)
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
    public func listPetnamesPublisher() -> AnyPublisher<[Petname], Error> {
        queue.future {
            try self.listPetnames()
        }
        .eraseToAnyPublisher()
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
    
    /// Get all petname changes since a CID. Returned petnames were changed
    /// in some way. It is up to you to read them to find out what happend
    /// (deletion, update, etc).
    /// - Returns an `AnyPublisher` for array of `Petname`
    public func getPetnameChangesPublisher(
        sinceCid: String
    ) -> AnyPublisher<[Petname], Error> {
        queue.future {
            try self.getPetnameChanges(sinceCid: sinceCid)
        }
        .eraseToAnyPublisher()
    }

    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres:
    ///
    /// `sphere().traverse(petname: "alice").traverse(petname: "bob").traverse(petname: "alice)` etc.
    ///
    /// - Returns a sphere
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
    
    /// Attempt to retrieve the sphere of a recorded petname, this can be chained to walk
    /// over multiple spheres.
    /// - Returns an `AnyPublisher` for  sphere
    public func traversePublisher(
        petname: Petname
    ) -> AnyPublisher<Sphere, Error> {
        queue.future {
            try self.traverse(petname: petname)
        }
        .eraseToAnyPublisher()
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
    /// Use `.savePublisher` instead if you are on the main thread.
    /// - Returns a version CID string
    @discardableResult public func save() throws -> String {
        try queue.sync {
            try _save()
        }
    }
    
    /// Save outstanding writes and return new Sphere version
    /// This method is called on the write queue, and is asynchronous.
    /// - Returns a `AnyPublisher` for version CID string, or error.
    public func savePublisher() -> AnyPublisher<String, Error> {
        queue.future {
            try self._save()
        }
        .eraseToAnyPublisher()
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
    /// Use `.removePublisher` instead if you are on the main thread.
    public func remove(slug: Slug) throws {
        try queue.sync {
            try self._remove(slug: slug)
        }
    }
    
    /// This method is called on the write queue, and is asynchronous.
    /// - Returns a `AnyPublisher` for Void (success) or error.
    public func removePublisher(slug: Slug) -> AnyPublisher<Void, Error> {
        queue.future {
            try self._remove(slug: slug)
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
    public func listPublisher() -> AnyPublisher<[Slug], Error> {
        queue.future {
            try self.list()
        }
        .eraseToAnyPublisher()
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
    /// Use `.syncPublisher` instead if on the main thread.
    /// - Returns a CID string for the new sphere version.
    public func sync() throws -> String {
        try queue.sync {
            try self._sync()
        }
    }
    
    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    /// This method runs on the write queue and is asynchronous.
    /// - Returns a `AnyPublisher` CID string for the new sphere version.
    public func syncPublisher() -> AnyPublisher<String, Error> {
        queue.future {
            try self._sync()
        }
        .eraseToAnyPublisher()
    }

    /// List all changed slugs between two versions of a sphere.
    /// This method lists which slugs changed between version, but not
    /// what changed.
    /// - Returns array of `Slug`
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
    
    /// List all changed slugs between two versions of a sphere.
    /// This method lists which slugs changed between version, but not
    /// what changed.
    /// - Returns `AnyPublisher` for array of `Slug`
    public func changesPublisher(
        _ since: String?
    ) -> AnyPublisher<[Slug], Error> {
        queue.future {
            try self.changes(since)
        }
        .eraseToAnyPublisher()
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
