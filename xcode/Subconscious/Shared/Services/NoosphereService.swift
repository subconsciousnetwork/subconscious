//
//  NoosphereService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/10/23.
//
//  Noosphere lifecycle:
//  1. Initialize namespace (once ever)
//  2. Create key (once per key)
//  3. Create sphere for key (once per key)
//  4. Retreive sphere identity from sphere creation receipt, then store (once, upon sphere creation)
//  5. Retrieve sphere mnemonic from sphere creation receipt. Display to user, then discard (once, upon sphere creation).
//  6. Open sphere file system (on-demand)

import Foundation
import SwiftNoosphere

public enum NoosphereError: Error {
    case foreignError(String)
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
    private let noosphere: OpaquePointer
    
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

    /// Perform an action with SphereFS using a closure.
    /// SphereFS pointer is freed after action is performed.
    /// - Returns: return value of `action` closure
    @discardableResult private func withSphereFS<T>(
        sphereIdentity: String,
        action: (OpaquePointer) throws -> T
    ) throws -> T {
        guard let sphereFS = ns_sphere_fs_open(
            noosphere,
            sphereIdentity
        ) else {
            throw NoosphereError.foreignError("Failed to get pointer for sphere file system")
        }
        defer {
            ns_sphere_fs_free(sphereFS)
        }
        return try action(sphereFS)
    }

    /// Read the value of a memo from a Sphere
    /// - Returns: `SphereMemo`
    func read(
        sphereIdentity: String,
        path: String
    ) throws -> SphereMemo {
        try withSphereFS(sphereIdentity: sphereIdentity) { sphereFS in
            guard let file = ns_sphere_fs_read(noosphere, sphereFS, path) else {
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

            let contents = ns_sphere_file_contents_read(noosphere, file)
            defer {
                ns_bytes_free(contents)
            }

            let data: Data = Data(bytes: contents.ptr, count: contents.len)

            return SphereMemo(contentType: contentType, data: data)
        }
    }

    func write(
        sphereIdentity: String,
        path: String,
        contentType: String,
        contents: Data
    ) throws {
        try withSphereFS(sphereIdentity: sphereIdentity) { sphereFS in
            contents.withUnsafeBytes({ rawBufferPointer in
                let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
                let pointer = bufferPointer.baseAddress!
                let contentsSlice = slice_ref_uint8(
                    ptr: pointer, len: contents.count
                )
                ns_sphere_fs_write(
                    noosphere,
                    sphereFS,
                    path,
                    contentType,
                    contentsSlice,
                    nil
                )
            })
            ns_sphere_fs_save(noosphere, sphereFS, nil)
        }
    }

    deinit {
        ns_free(noosphere)
    }
}
