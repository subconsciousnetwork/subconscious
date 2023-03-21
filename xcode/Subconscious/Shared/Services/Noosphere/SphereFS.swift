//
//  SphereFS.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/13/23.
//

import Foundation
import SwiftNoosphere
import os

/// Describes a Sphere.
/// See `SphereFS` for a concrete implementation.
public protocol SphereProtocol {
    associatedtype Memo
    
    func version() throws -> String
    
    func getFileVersion(slashlink: String) -> String?
    
    func readHeaderValueFirst(
        slashlink: String,
        name: String
    ) -> String?
    
    func readHeaderNames(slashlink: String) -> [String]
    
    func read(slashlink: String) throws -> Memo
    
    func write(
        slug: String,
        contentType: String,
        additionalHeaders: [Header],
        body: Data
    ) throws
    
    func remove(slug: String) throws
    
    func save() throws -> String
    
    func list() throws -> [String]
    
    func sync() throws -> String
    
    func changes(_ since: String?) throws -> [String]
}

protocol SphereIdentityProtocol {
    func identity() throws -> String
}

enum SphereFSError: Error, LocalizedError {
    case contentTypeMissing(_ slashlink: String)
    case fileDoesNotExist(_ slashlink: String)
    
    var errorDescription: String? {
        switch self {
        case .contentTypeMissing(let slashlink):
            return "Content-Type header is missing for file: \(slashlink)"
        case .fileDoesNotExist(let slashlink):
            return "File does not exist: \(slashlink)"
        }
    }
}


/// Sphere file system access.
/// Provides sphere file system methods and manages lifetime of sphere pointer.
public final class SphereFS: SphereProtocol {
    private let logger = Logger(
        subsystem: Config.default.rdns,
        category: "SphereFS"
    )
    private let noosphere: Noosphere
    public let fs: OpaquePointer
    public let identity: String
    
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self.identity = identity
        guard let fs = try Noosphere.callWithError(
            ns_sphere_fs_open,
            noosphere.noosphere,
            identity
        ) else {
            throw NoosphereError.nullPointer
        }
        self.fs = fs
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
        slashlink: String,
        name: String
    ) -> String? {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_fs_read,
            noosphere.noosphere,
            fs,
            slashlink
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
    public func getFileVersion(slashlink: String) -> String? {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_fs_read,
            noosphere.noosphere,
            fs,
            slashlink
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
    public func readHeaderNames(slashlink: String) -> [String] {
        guard let file = try? Noosphere.callWithError(
            ns_sphere_fs_read,
            noosphere.noosphere,
            fs,
            slashlink
        ) else {
            return []
        }
        defer {
            ns_sphere_file_free(file)
        }
        return Self.readFileHeaderNames(file: file)
    }
    
    /// Read the value of a memo from a Sphere
    /// - Returns: `Memo`
    public func read(slashlink: String) throws -> MemoData {
        guard let file = try Noosphere.callWithError(
            ns_sphere_fs_read,
            noosphere.noosphere,
            fs,
            slashlink
        ) else {
            throw SphereFSError.fileDoesNotExist(slashlink)
        }
        defer {
            ns_sphere_file_free(file)
        }
        
        guard let contentType = Self.readFileHeaderValueFirst(
            file: file,
            name: "Content-Type"
        ) else {
            throw SphereFSError.contentTypeMissing(slashlink)
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
        slug: String,
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
                ns_sphere_fs_write(
                    noosphere.noosphere,
                    fs,
                    slug,
                    contentType,
                    bodyRaw,
                    additionalHeadersContainer,
                    error
                )
            }
        })
    }
    
    public func getPetname(petname: String) throws -> String {
        let name = try Noosphere.callWithError(
            ns_sphere_petname_get,
            noosphere.noosphere,
            fs,
            petname
        )
        
        guard let name = name else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(name)
        }
        
        return String(cString: name)
    }
    
    public func setPetname(did: String, petname: String) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            fs,
            petname,
            did
        )
    }
    
    public func unsetPetname(petname: String) throws {
        try Noosphere.callWithError(
            ns_sphere_petname_set,
            noosphere.noosphere,
            fs,
            petname,
            nil
        )
    }
    
    public func resolvePetname(petname: String) throws -> String {
        let did = try Noosphere.callWithError(
            ns_sphere_petname_resolve,
            noosphere.noosphere,
            fs,
            petname
        )
        
        guard let did = did else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(did)
        }
        
        return String(cString: did)
    }
    
    public func listPetnames() throws -> [String] {
        let petnames = try Noosphere.callWithError(
            ns_sphere_petname_list,
            noosphere.noosphere,
            fs
        )
        
        defer {
            ns_string_array_free(petnames)
        }
        
        return petnames.toStringArray()
    }
    
    public func getPetnameChanges(sinceCid: String) throws -> [String] {
        let changes = try Noosphere.callWithError(
            ns_sphere_petname_changes,
            noosphere.noosphere,
            fs,
            sinceCid
        )
        defer {
            ns_string_array_free(changes)
        }
        
        return changes.toStringArray()
    }
    
    /// Save outstanding writes and return new Sphere version
    @discardableResult public func save() throws -> String {
        try Noosphere.callWithError(
            ns_sphere_fs_save,
            noosphere.noosphere,
            fs,
            nil
        )
        return try self.version()
    }
    
    /// Remove slug from sphere
    public func remove(slug: String) throws {
        try Noosphere.callWithError(
            ns_sphere_fs_remove,
            noosphere.noosphere,
            fs,
            slug
        )
    }
    
    /// List all slugs in sphere
    public func list() throws -> [String] {
        let slugs = try Noosphere.callWithError(
            ns_sphere_fs_list,
            noosphere.noosphere,
            fs
        )
        defer {
            ns_string_array_free(slugs)
        }
        
        return slugs.toStringArray()
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
    public func changes(_ since: String? = nil) throws -> [String] {
        let changes = try Noosphere.callWithError(
            ns_sphere_fs_changes,
            noosphere.noosphere,
            fs,
            since
        )
        defer {
            ns_string_array_free(changes)
        }
        
        return changes.toStringArray()
    }
    
    deinit {
        ns_sphere_fs_free(fs)
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
