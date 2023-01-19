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
    /// Thrown when trying to read a memo that does not exist.
    case memoDoesNotExist
}

public struct SphereReceipt {
    var identity: String
    var mnemonic: String
}

struct SphereMemo: Hashable {
    var contentType: String
    var data: Data
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

public final class Sphere {
    private let noosphere: Noosphere
    let fs: OpaquePointer
    let identity: String
    
    init(noosphere: Noosphere, identity: String) throws {
        self.noosphere = noosphere
        self.identity = identity
        
        guard let fs = ns_sphere_fs_open(
            noosphere.noosphere,
            identity
        ) else {
            throw NoosphereError.foreignError("Failed to get pointer for sphere file system")
        }
        self.fs = fs
    }
    
    /// Read the value of a memo from a Sphere
    /// - Returns: `SphereMemo`
    func read(slashlink: String) throws -> SphereMemo {
        guard let file = ns_sphere_fs_read(
            noosphere.noosphere,
            fs,
            slashlink
        ) else {
            throw NoosphereError.memoDoesNotExist
        }
        defer {
            ns_sphere_file_free(file)
        }
        
        let contentTypeValues = ns_sphere_file_header_values_read(
            file,
            "Content-Type"
        )
        defer {
            ns_string_array_free(contentTypeValues)
        }
        
        let contentType = String(cString: contentTypeValues.ptr.pointee!)
        
        let contents = ns_sphere_file_contents_read(noosphere.noosphere, file)
        defer {
            ns_bytes_free(contents)
        }
        
        let data: Data = Data(bytes: contents.ptr, count: contents.len)
        
        return SphereMemo(contentType: contentType, data: data)
    }
    
    /// Write to sphere
    func write(
        slug: String,
        contentType: String,
        contents: Data
    ) throws {
        contents.withUnsafeBytes({ rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            let pointer = bufferPointer.baseAddress!
            let contentsSlice = slice_ref_uint8(
                ptr: pointer, len: contents.count
            )
            ns_sphere_fs_write(
                noosphere.noosphere,
                fs,
                slug,
                contentType,
                contentsSlice,
                nil
            )
        })
    }
    
    /// Save outstanding writes
    func save() {
        ns_sphere_fs_save(noosphere.noosphere, fs, nil)
    }

    deinit {
        ns_sphere_fs_free(fs)
    }
}

enum NoosphereServiceError: Error {
    case sphereNotFound(String)
    case sphereExists(String)
}

/// Creates and manages Noosphere and Spheres.
/// Handles persisting settings to UserDefaults.
final class NoosphereService {
    var userDefaults = UserDefaults.standard
    var noosphere: Noosphere

    init(
        globalStoragePath: String,
        sphereStoragePath: String
    ) throws {
        /// Initialize Noosphere
        self.noosphere = try Noosphere(
            globalStoragePath: Config.default.noosphere.globalStoragePath,
            sphereStoragePath: Config.default.noosphere.sphereStoragePath
        )
    }

    /// Get the sphere identity stored in user defaults, if any
    /// - Returns: identity string, or nil
    func getSphereIdentity() -> String? {
        userDefaults.string(forKey: "sphereIdentity")
    }

    /// Get a Sphere for the identity stored in user defaults.
    /// - Returns: Sphere, or nil
    func getSphere() throws -> Sphere {
        guard let identity = getSphereIdentity() else {
            throw NoosphereServiceError.sphereNotFound(
                "Could not find sphere for user."
            )
        }
        return try Sphere(noosphere: self.noosphere, identity: identity)
    }

    /// Create a default sphere for user.
    /// - Returns: SphereReceipt
    /// Will not create sphere if a sphereIdentity already appears in
    /// the user defaults.
    func createSphere() throws -> SphereReceipt {
        guard userDefaults.string(forKey: "sphereIdentity") == nil else {
            throw NoosphereServiceError.sphereExists(
                "A default Sphere already exists for this user. Doing nothing."
            )
        }
        let sphereReceipt = try noosphere.createSphere(
            ownerKeyName: Config.default.noosphere.ownerKeyName
        )
        // Persist sphere identity to user defaults.
        // NOTE: we do not persist the mnemonic, since it would be insecure.
        // Instead, we return the receipt so that mnemonic can be displayed
        // and discarded.
        userDefaults.set(sphereReceipt.identity, forKey: "sphereIdentity")
        return sphereReceipt
    }
}
