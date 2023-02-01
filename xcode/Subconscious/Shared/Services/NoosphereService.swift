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

public enum NoosphereError: Error {
    /// Thrown when something unexpected happens on the other side of the FFI, and we don't know what went wrong.
    case foreignError(String)
}

public struct SphereReceipt {
    var identity: String
    var mnemonic: String
}

struct NSUtils {
    /// Read an error message from an unsafe mutable pointer to an error
    /// on the Rust side.
    static func readErrorMessage(
        _ error: UnsafeMutablePointer<OpaquePointer?>
    ) -> String? {
        guard let errorMessagePointer = ns_error_string(error.pointee) else {
            return nil
        }
        defer {
            ns_string_free(errorMessagePointer)
        }
        let errorMessage = String.init(cString: errorMessagePointer)
        return errorMessage
    }
}

/// Create a Noosphere instance.
///
/// - Property noosphere: pointer that holds all the internal book keeping.
///   DB pointers, key storage interfaces, active HTTP clients etc.
public final class Noosphere {
    let noosphere: OpaquePointer
    
    init(
        globalStoragePath: String,
        sphereStoragePath: String
    ) throws {
        guard let noosphere = ns_initialize(
            globalStoragePath,
            sphereStoragePath,
            nil
        ) else {
            throw NoosphereError.foreignError(
                "Failed to get pointer for Noosphere"
            )
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
        ns_key_create(noosphere, ownerKeyName)
        
        guard let sphereReceipt = ns_sphere_create(
            noosphere,
            ownerKeyName
        ) else {
            throw NoosphereError.foreignError(
                "Failed to get pointer for sphere receipt"
            )
        }
        defer {
            ns_sphere_receipt_free(sphereReceipt)
        }
        
        guard let sphereIdentityPointer = ns_sphere_receipt_identity(
            sphereReceipt
        ) else {
            throw NoosphereError.foreignError(
                "Failed to get pointer for identity"
            )
        }
        defer {
            ns_string_free(sphereIdentityPointer)
        }
        
        guard let sphereMnemonicPointer = ns_sphere_receipt_mnemonic(
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

    func save() throws
    
    func list() -> [String]
}

public final class Sphere: SphereProtocol {
    private let noosphere: Noosphere
    let fs: OpaquePointer
    let identity: String
    
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self.identity = identity
        
        let error = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        defer {
            ns_error_free(error.pointee)
        }

        guard let fs = ns_sphere_fs_open(
            noosphere.noosphere,
            identity,
            error
        ) else {
            let message = NSUtils.readErrorMessage(error) ?? "Unknown"
            throw NoosphereError.foreignError(message)
        }

        self.fs = fs
    }
    
    /// Read first header value for memo at slashlink
    /// - Returns: value, if any
    public func readHeaderValueFirst(
        slashlink: String,
        name: String
    ) -> String? {
        guard let file = ns_sphere_fs_read(
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

    /// Read all header names for a given slashlink
    public func readHeaderNames(slashlink: String) -> [String] {
        guard let file = ns_sphere_fs_read(
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
    public func read(slashlink: String) -> MemoData? {
        guard let file = ns_sphere_fs_read(
            noosphere.noosphere,
            fs,
            slashlink
        ) else {
            return nil
        }
        defer {
            ns_sphere_file_free(file)
        }
        
        guard let contentType = Self.readFileHeaderValueFirst(
            file: file,
            name: "Content-Type"
        ) else {
            return nil
        }

        let bodyRaw = ns_sphere_file_contents_read(noosphere.noosphere, file)
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
            
            ns_sphere_fs_write(
                noosphere.noosphere,
                fs,
                slug,
                contentType,
                bodyRaw,
                additionalHeadersContainer
            )
        })
    }
    
    /// Save outstanding writes
    public func save() throws {
        ns_sphere_fs_save(noosphere.noosphere, fs, nil)
    }
    
    public func remove(slug: String) throws {
        
    }

    public func list() -> [String] {
        return []
    }
    
    deinit {
        ns_sphere_fs_free(fs)
    }
    
    /// Read first header value for file pointer
    private static func readFileHeaderValueFirst(
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
    private static func readFileHeaderNames(
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

enum NoosphereServiceError: Error {
    case sphereNotFound(String)
    case sphereExists(String)
}

/// Creates and manages Noosphere and Spheres.
/// Handles persisting settings to UserDefaults.
final class NoosphereService {
    var globalStorageURL: URL
    var sphereStorageURL: URL
    /// Memoized Noosphere instance
    private var _noosphere: Noosphere?
    /// Memoized Sphere instance for default user sphere
    private var _sphere: Sphere?
    
    init(
        globalStorageURL: URL,
        sphereStorageURL: URL
    ) {
        self.globalStorageURL = globalStorageURL
        self.sphereStorageURL = sphereStorageURL
        self._noosphere = try? getNoosphere()
    }
    
    /// Gets or creates memoized Noosphere singleton instance
    func getNoosphere() throws -> Noosphere {
        if let noosphere = self._noosphere {
            return noosphere
        }
        let noosphere = try Noosphere(
            globalStoragePath: globalStorageURL.path(percentEncoded: false),
            sphereStoragePath: sphereStorageURL.path(percentEncoded: false)
        )
        self._noosphere = noosphere
        return noosphere
    }
    
    /// Get the sphere identity stored in user defaults, if any
    /// - Returns: identity string, or nil
    func getSphereIdentity() -> String? {
        UserDefaults.standard.string(forKey: "sphereIdentity")
    }
    
    /// Get a Sphere for the identity stored in user defaults.
    /// - Returns: Sphere
    func getSphere() throws -> Sphere {
        if let sphere = self._sphere {
            return sphere
        }
        guard let identity = getSphereIdentity() else {
            throw NoosphereServiceError.sphereNotFound(
                "Could not find sphere for user."
            )
        }
        let noosphere = try getNoosphere()
        let sphere = try Sphere(noosphere: noosphere, identity: identity)
        self._sphere = sphere
        return sphere
    }
    
    /// Create a default sphere for user.
    /// - Returns: SphereReceipt
    /// Will not create sphere if a sphereIdentity already appears in
    /// the user defaults.
    func createSphere(ownerKeyName: String) throws -> SphereReceipt {
        guard UserDefaults.standard.string(
            forKey: "sphereIdentity"
        ) == nil else {
            throw NoosphereServiceError.sphereExists(
                "A default Sphere already exists for this user. Doing nothing."
            )
        }
        let noosphere = try getNoosphere()
        let sphereReceipt = try noosphere.createSphere(
            ownerKeyName: ownerKeyName
        )
        // Persist sphere identity to user defaults.
        // NOTE: we do not persist the mnemonic, since it would be insecure.
        // Instead, we return the receipt so that mnemonic can be displayed
        // and discarded.
        UserDefaults.standard.set(
            sphereReceipt.identity,
            forKey: "sphereIdentity"
        )
        return sphereReceipt
    }
}
