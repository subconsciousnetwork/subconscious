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

public enum NoosphereError: Error, LocalizedError {
    /// Thrown when something unexpected happens on the other side of the FFI, and we don't know what went wrong.
    case foreignError(String)
    /// Thrown when an OpaquePointer? is unwrapped and found to be a null pointer.
    case nullPointer
    
    public var errorDescription: String? {
        switch self {
        case .foreignError(let message):
            return "Foreign Error: \(message)"
        case .nullPointer:
            return "Null pointer"
        }
    }
}

struct NoosphereFFI {
    static func callWithError<Z>(
        _ perform: (UnsafeMutablePointer<OpaquePointer?>) -> Z
    ) throws -> Z {
        let error = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        defer {
            error.deallocate()
        }
        let value = perform(error)
        if let errorPointer = error.pointee {
            defer {
                ns_error_free(errorPointer)
            }
            guard let errorMessagePointer = ns_error_string(
                errorPointer
            ) else {
                throw NoosphereError.foreignError("Unknown")
            }
            defer {
                ns_string_free(errorMessagePointer)
            }
            let errorMessage = String.init(cString: errorMessagePointer)
            throw NoosphereError.foreignError(errorMessage)
        }
        return value
    }
    
    static func callWithError<A, Z>(
        _ perform: (A, UnsafeMutablePointer<OpaquePointer?>) -> Z,
        _ a: A
    ) throws -> Z {
        try Self.callWithError { error in perform(a, error) }
    }
    
    static func callWithError<A, B, Z>(
        _ perform: (A, B, UnsafeMutablePointer<OpaquePointer?>) -> Z,
        _ a: A,
        _ b: B
    ) throws -> Z {
        try Self.callWithError { error in perform(a, b, error) }
    }
    
    static func callWithError<A, B, C, Z>(
        _ perform: (A, B, C, UnsafeMutablePointer<OpaquePointer?>) -> Z,
        _ a: A,
        _ b: B,
        _ c: C
    ) throws -> Z {
        try Self.callWithError { error in perform(a, b, c, error) }
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

        let name_count = file_header_names.len
        guard var pointer = file_header_names.ptr else {
            return []
        }

        var names: [String] = []
        for _ in 0..<name_count {
            let name = String(cString: pointer.pointee!)
            names.append(name)
            pointer += 1;
        }
        return names
    }
}

public struct SphereReceipt {
    var identity: String
    var mnemonic: String
}

/// Create a Noosphere instance.
///
/// - Property noosphere: pointer that holds all the internal book keeping.
///   DB pointers, key storage interfaces, active HTTP clients etc.
public final class Noosphere {
    let noosphere: OpaquePointer
    
    init(
        globalStoragePath: String,
        sphereStoragePath: String,
        gatewayURL: String? = nil
    ) throws {
        guard let noosphere = try NoosphereFFI.callWithError(
            ns_initialize,
            globalStoragePath,
            sphereStoragePath,
            gatewayURL
        ) else {
            throw NoosphereError.nullPointer
        }
        self.noosphere = noosphere
    }
    
    /// Create and configure a user and sphere
    /// - Important: the identity should be persisted
    /// - Important: the mnemonic should be displayed to user and then discarded.
    /// - Returns: a SphereConfig containing the sphere identity and mnemonic
    ///
    /// What it does:
    /// - Initializes a namespace
    /// - Creates a key
    /// - Creates a sphere for that key
    public func createSphere(
        ownerKeyName: String
    ) throws -> SphereReceipt {
        try NoosphereFFI.callWithError(
            ns_key_create,
            noosphere,
            ownerKeyName
        )
        
        guard let sphereReceipt = try NoosphereFFI.callWithError(
            ns_sphere_create,
            noosphere,
            ownerKeyName
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_sphere_receipt_free(sphereReceipt)
        }
        
        guard let sphereIdentityPointer = try NoosphereFFI.callWithError(
            ns_sphere_receipt_identity,
            sphereReceipt
        ) else {
            throw NoosphereError.foreignError(
                "Failed to get pointer for identity"
            )
        }
        defer {
            ns_string_free(sphereIdentityPointer)
        }
        
        guard let sphereMnemonicPointer = try NoosphereFFI.callWithError(
            ns_sphere_receipt_mnemonic,
            sphereReceipt
        ) else {
            throw NoosphereError.foreignError(
                "Failed to get pointer for mnemonic"
            )
        }
        defer {
            ns_string_free(sphereMnemonicPointer)
        }
        
        let sphereIdentity = String.init(cString: sphereIdentityPointer)
        let sphereMnemonic = String.init(cString: sphereMnemonicPointer)
        
        return SphereReceipt(
            identity: sphereIdentity,
            mnemonic: sphereMnemonic
        )
    }
    
    deinit {
        ns_free(noosphere)
    }
}

public protocol SphereProtocol {
    associatedtype Memo
    
    func version() throws -> String
    
    func getFileVersion(slashlink: String) -> String?
    
    func readHeaderValueFirst(
        slashlink: String,
        name: String
    ) -> String?
    
    func readHeaderNames(slashlink: String) -> [String]
    
    func read(slashlink: String) -> Memo?
    
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

public final class SphereFS: SphereProtocol {
    private let noosphere: Noosphere
    public let fs: OpaquePointer
    public let identity: String
    
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self.identity = identity
        guard let fs = try NoosphereFFI.callWithError(
            ns_sphere_fs_open,
            noosphere.noosphere,
            identity
        ) else {
            throw NoosphereError.nullPointer
        }
        self.fs = fs
    }
    
    /// Get current version of sphere
    public func version() throws -> String {
        guard let sphereVersionPointer = try NoosphereFFI.callWithError(
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
        guard let file = try? NoosphereFFI.callWithError(
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
        return NoosphereFFI.readFileHeaderValueFirst(
            file: file,
            name: name
        )
    }
    
    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    public func getFileVersion(slashlink: String) -> String? {
        guard let file = try? NoosphereFFI.callWithError(
            ns_sphere_fs_read,
            noosphere.noosphere,
            fs,
            slashlink
        ) else {
            return nil
        }
        guard let cid = try? NoosphereFFI.callWithError(
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
        guard let file = try? NoosphereFFI.callWithError(
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
        return NoosphereFFI.readFileHeaderNames(file: file)
    }
    
    /// Read the value of a memo from a Sphere
    /// - Returns: `Memo`
    public func read(slashlink: String) -> MemoData? {
        guard let file = try? NoosphereFFI.callWithError(
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
        
        guard let contentType = NoosphereFFI.readFileHeaderValueFirst(
            file: file,
            name: "Content-Type"
        ) else {
            return nil
        }
        
        guard let bodyRaw = try? NoosphereFFI.callWithError(
            ns_sphere_file_contents_read,
            noosphere.noosphere, file
        ) else {
            return nil
        }
        defer {
            ns_bytes_free(bodyRaw)
        }
        let body = Data(bytes: bodyRaw.ptr, count: bodyRaw.len)
        
        var headers: [Header] = []
        let headerNames = NoosphereFFI.readFileHeaderNames(file: file)
        for name in headerNames {
            // Skip content type. We've already retreived it.
            guard name != "Content-Type" else {
                continue
            }
            guard let value = NoosphereFFI.readFileHeaderValueFirst(
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
            
            try NoosphereFFI.callWithError { error in
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

    /// Save outstanding writes and return new Sphere version
    @discardableResult public func save() throws -> String {
        try NoosphereFFI.callWithError(
            ns_sphere_fs_save,
            noosphere.noosphere,
            fs,
            nil
        )
        return try self.version()
    }
    
    /// Remove slug from sphere
    public func remove(slug: String) throws {
        try NoosphereFFI.callWithError(
            ns_sphere_fs_remove,
            noosphere.noosphere,
            fs,
            slug
        )
    }
    
    /// List all slugs in sphere
    public func list() throws -> [String] {
        let slugs = try NoosphereFFI.callWithError(
            ns_sphere_fs_list,
            noosphere.noosphere,
            fs
        )
        defer {
            ns_string_array_free(slugs)
        }

        let slugCount = slugs.len
        var pointer = slugs.ptr!

        var output: [String] = []
        for _ in 0..<slugCount {
            let slug = String.init(cString: pointer.pointee!)
            output.append(slug)
            pointer += 1;
        }
        return output
    }

    /// Sync sphere with gateway.
    /// Gateway must be configured when Noosphere was initialized.
    public func sync() throws -> String {
        let versionPointer = try NoosphereFFI.callWithError(
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
        let changes = try NoosphereFFI.callWithError(
            ns_sphere_fs_changes,
            noosphere.noosphere,
            fs,
            since
        )
        defer {
            ns_string_array_free(changes)
        }

        let changesCount = changes.len
        var pointer = changes.ptr!
        
        var slugs: [String] = []
        for _ in 0..<changesCount {
            let slug = String.init(cString: pointer.pointee!)
            slugs.append(slug)
            pointer += 1;
        }
        return slugs
    }

    deinit {
        ns_sphere_fs_free(fs)
    }
}

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
    
    func read(slashlink: String) -> MemoData? {
        try? self.sphere().read(slashlink: slashlink)
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
