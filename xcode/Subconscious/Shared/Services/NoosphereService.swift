//
//  NoosphereService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/10/23.
//

import Foundation
import SwiftNoosphere

public enum NoosphereServiceError: Error {
    case unwrap(String)
}

/// A Swift Wrapper for Noosphere.
/// This class is designed to follow RAII pattern https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization.
/// Memory is automatically freed when the class is deallocated.
public final class NoosphereService {
    public let keyName: String
    public let globalStoragePath: String
    public let sphereStoragePath: String
    public let sphereIdentity: String
    public let sphereMnemonic: String
    private let noosphere: OpaquePointer
    private let sphereReceipt: OpaquePointer
    private let sphereIdentityPointer: UnsafeMutablePointer<CChar>
    private let sphereMnemonicPointer: UnsafeMutablePointer<CChar>

    init(
        keyName: String,
        globalStoragePath: String,
        sphereStoragePath: String
    ) throws {
        self.keyName = keyName
        self.globalStoragePath = globalStoragePath
        self.sphereStoragePath = sphereStoragePath
        self.noosphere = ns_initialize(
            self.globalStoragePath,
            self.sphereStoragePath,
            nil
        )
        
        ns_key_create(noosphere, keyName)

        self.sphereReceipt = ns_sphere_create(noosphere, self.keyName)

        guard let sphereIdentityPointer = ns_sphere_receipt_identity(sphereReceipt) else {
            throw NoosphereServiceError.unwrap("Failed to unwrap Sphere identity pointer")
        }
        self.sphereIdentityPointer = sphereIdentityPointer

        guard let sphereMnemonicPointer = ns_sphere_receipt_mnemonic(sphereReceipt) else {
            throw NoosphereServiceError.unwrap("Failed to unwrap Sphere mnemonic pointer")
        }
        self.sphereMnemonicPointer = sphereMnemonicPointer
        self.sphereIdentity = String.init(cString: sphereIdentityPointer)
        self.sphereMnemonic = String.init(cString: sphereMnemonicPointer)
    }

    deinit {
        ns_string_free(self.sphereIdentityPointer)
        ns_string_free(self.sphereMnemonicPointer)
        ns_sphere_receipt_free(self.sphereReceipt)
        ns_free(self.noosphere)
    }
}
