//
//  Sphere.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/13/23.
//

import Foundation
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
    
    func setPetname(did: String, petname: Petname) throws
    
    func unsetPetname(petname: Petname) throws
    
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

protocol SphereIdentityProtocol {
    func identity() throws -> String
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
public final class Sphere: SphereProtocol {
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "Sphere"
    )
    private let noosphere: Noosphere
    public let sphere: OpaquePointer
    public let identity: String
    
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
    
    /// Get current version of sphere
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
    
    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
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
    
    /// Read all header names for a given slashlink
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
    
    public func setPetname(did: String, petname: Petname) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            sphere,
            petname.description,
            did
        )
    }
    
    public func unsetPetname(petname: Petname) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            sphere,
            petname.description,
            nil
        )
    }
    
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
    
    /// Save outstanding writes and return new Sphere version
    @discardableResult public func save() throws -> String {
        try Noosphere.callWithError(
            ns_sphere_save,
            noosphere.noosphere,
            sphere,
            nil
        )
        return try self.version()
    }
    
    /// Remove slug from sphere
    public func remove(slug: Slug) throws {
        try Noosphere.callWithError(
            ns_sphere_content_remove,
            noosphere.noosphere,
            sphere,
            slug.description
        )
    }
    
    /// List all slugs in sphere
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
    
    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    public func sync() throws -> String {
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
