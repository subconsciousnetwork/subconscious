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

public enum NoosphereServiceError: Error {
    case foreignError(String)
}

public struct SphereConfig {
    var identity: String
    var mnemonic: String
}

/// A Swift Wrapper for Noosphere.
/// This class is designed to follow RAII pattern https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization.
/// Memory is automatically freed when the class is deallocated.
public final class NoosphereService {
    /// Create and configure a user and sphere
    /// - Important: the identity should be persisted
    /// - Important: the mnemonic should be displayed to user and then discarded.
    /// - Returns: a SphereConfig containing the sphere identity and mnemonic
    ///
    /// What it does:
    /// - Initializes a namespace
    /// - Creates a key
    /// - Creates a sphere for that key
    public static func create(
        ownerKeyName: String,
        globalStoragePath: String,
        sphereStoragePath: String
    ) throws -> SphereConfig {
        guard let noosphere = ns_initialize(
            globalStoragePath,
            sphereStoragePath,
            nil
        ) else {
            throw NoosphereServiceError.foreignError(
                "Failed to get pointer for namespace"
            )
        }
        defer {
            ns_free(noosphere)
        }
        
        ns_key_create(noosphere, ownerKeyName)
        
        guard let sphereReceipt = ns_sphere_create(
            noosphere,
            ownerKeyName
        ) else {
            throw NoosphereServiceError.foreignError(
                "Failed to get pointer for sphere receipt"
            )
        }
        defer {
            ns_sphere_receipt_free(sphereReceipt)

        }
        
        guard let sphereIdentityPointer = ns_sphere_receipt_identity(
            sphereReceipt
        ) else {
            throw NoosphereServiceError.foreignError(
                "Failed to get pointer for identity"
            )
        }
        defer {
            ns_string_free(sphereIdentityPointer)
        }
        
        guard let sphereMnemonicPointer = ns_sphere_receipt_mnemonic(
            sphereReceipt
        ) else {
            throw NoosphereServiceError.foreignError(
                "Failed to get pointer for mnemonic"
            )
        }
        defer {
            ns_string_free(sphereMnemonicPointer)
        }
        
        let sphereIdentity = String.init(cString: sphereIdentityPointer)
        let sphereMnemonic = String.init(cString: sphereMnemonicPointer)
        
        return SphereConfig(
            identity: sphereIdentity,
            mnemonic: sphereMnemonic
        )
    }
}
