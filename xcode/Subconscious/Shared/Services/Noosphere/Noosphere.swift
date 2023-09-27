//
//  Noosphere.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/13/23.
//
//  Noosphere lifecycle:
//  1. Initialize namespace (once ever)
//  2. Create a unique key (once per key)
//  3. Create sphere for key, getting back a receipt (once per key)
//     - Retrieve identity from sphere receipt, then store (once, upon sphere creation)
//     - Retrieve sphere mnemonic from sphere receipt. Display to user, then discard (once, upon sphere creation)
//  4. Open sphere file system (on-demand)

import Foundation
import Combine
import SwiftNoosphere
import os

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

public struct SphereReceipt:
    CustomStringConvertible,
    CustomDebugStringConvertible
{
    public var identity: String
    // !!!: Mnemonic is a secret and should never be logged or persisted
    public var mnemonic: String
    
    /// Define custom description to avoid accidentally revealing mnemonic
    /// if describing receipt as string.
    public var description: String {
        "SphereReceipt(identity: \(identity), mnemonic: *****)"
    }
    
    /// Define custom debug description to avoid accidentally revealing mnemonic
    /// if logging or debuging receipt.
    public var debugDescription: String {
        "SphereReceipt(identity: \(identity), mnemonic: *****)"
    }
}

/// Create a Noosphere instance.
///
/// - Property noosphere: pointer that holds all the internal book keeping.
///   DB pointers, key storage interfaces, active HTTP clients etc.
public actor Noosphere {
    /// Wraps `NS_NOOSPHERE_LOG_*` constants
    enum NoosphereLogLevel: UInt32 {
        /// Equivalent to minimal format / INFO filter
        case basic
        /// Equivalent to minimal format / DEBUG filter
        case chatty
        /// Equivalent to minimal format / OFF filter
        case silent
        /// Equivalent to pretty format / DEBUG filter
        case academic
        /// Equivalent to verbose format / DEBUG filter
        case informed
        /// Equivalent to verbose format / TRACE filter
        case tiresome
        /// Equivalent to pretty format / TRACE filter
        case deafening
        
        var rawValue: UInt32 {
            switch self {
            case .basic:
                return NS_NOOSPHERE_LOG_BASIC.rawValue
            case .chatty:
                return NS_NOOSPHERE_LOG_CHATTY.rawValue
            case .silent:
                return NS_NOOSPHERE_LOG_SILENT.rawValue
            case .academic:
                return NS_NOOSPHERE_LOG_ACADEMIC.rawValue
            case .informed:
                return NS_NOOSPHERE_LOG_INFORMED.rawValue
            case .tiresome:
                return NS_NOOSPHERE_LOG_TIRESOME.rawValue
            case .deafening:
                return NS_NOOSPHERE_LOG_DEAFENING.rawValue
            }
        }
    }

    private let logger: Logger = Logger(
        subsystem: Config.default.rdns,
        category: "Noosphere"
    )
    let noosphere: OpaquePointer
    let globalStoragePath: String
    let sphereStoragePath: String
    let gatewayURL: String?
    
    init(
        globalStoragePath: String,
        sphereStoragePath: String,
        gatewayURL: String? = nil,
        noosphereLogLevel: NoosphereLogLevel = .basic
    ) throws {
        ns_tracing_initialize(noosphereLogLevel.rawValue)
        guard let noosphere = try Self.callWithError(
            ns_initialize,
            globalStoragePath,
            sphereStoragePath,
            gatewayURL
        ) else {
            throw NoosphereError.nullPointer
        }
        self.noosphere = noosphere
        self.globalStoragePath = globalStoragePath
        self.sphereStoragePath = sphereStoragePath
        self.gatewayURL = gatewayURL
        logger.debug("init")
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
        try Self.callWithError(
            ns_key_create,
            noosphere,
            ownerKeyName
        )
        
        guard let sphereReceipt = try Self.callWithError(
            ns_sphere_create,
            noosphere,
            ownerKeyName
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_sphere_receipt_free(sphereReceipt)
        }
        
        guard let sphereIdentityPointer = try Self.callWithError(
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
        
        guard let sphereMnemonicPointer = try Self.callWithError(
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

        logger.log("Created sphere with identity \(sphereIdentity)")

        return SphereReceipt(
            identity: sphereIdentity,
            mnemonic: sphereMnemonic
        )
    }
    
    nonisolated func createSpherePublisher(
        ownerKeyName: String
    ) -> AnyPublisher<SphereReceipt, Error> {
        Future.detached {
            try await self.createSphere(ownerKeyName: ownerKeyName)
        }
        .eraseToAnyPublisher()
    }
    
    func recover(identity: Did, localKeyName: String, mnemonic: RecoveryPhrase) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            nsSphereRecover(
                noosphere,
                identity.did,
                localKeyName,
                mnemonic.mnemonic
            ) { error in
                if let error = Noosphere.readErrorMessage(error) {
                    continuation.resume(
                        throwing: NoosphereError.foreignError(error)
                    )
                    return
                }
                
                continuation.resume(returning: true)
                return
            }
        }
    }

    deinit {
        ns_free(noosphere)
        logger.debug("deinit")
    }
    
    /// Read a string from a pointer to a C string, freeing pointer.
    /// - Returns string, or nil if pointer is not intialized.
    static func readString(
        _ pointer: UnsafeMutablePointer<CChar>?
    ) -> String? {
        guard let pointer = pointer else {
            return nil
        }
        defer {
            ns_string_free(pointer)
        }
        let message = String(cString: pointer)
        return message
    }

    /// Read an error message from an error messsage pointer.
    /// Frees error, if any.
    /// - Returns error string, or nil if pointer is not intialized (no error)
    static func readErrorMessage(_ error: OpaquePointer?) -> String? {
        guard let error = error else {
            return nil
        }
        defer {
            ns_error_free(error)
        }
        guard let errorMessagePointer = ns_error_message_get(error) else {
            return nil
        }
        defer {
            ns_string_free(errorMessagePointer)
        }
        let message = String(cString: errorMessagePointer)
        return message
    }

    static func callWithError<Z>(
        _ perform: (UnsafeMutablePointer<OpaquePointer?>) -> Z
    ) throws -> Z {
        let error = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        // Explicitly clear this memory before use
        error.pointee = nil
        
        defer {
            error.deallocate()
        }
        let value = perform(error)
        if let errorPointer = error.pointee {
            defer {
                ns_error_free(errorPointer)
            }
            guard let errorMessagePointer = ns_error_message_get(
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
    
    static func callWithError<A, B, C, D, Z>(
        _ perform: (A, B, C, D, UnsafeMutablePointer<OpaquePointer?>) -> Z,
        _ a: A,
        _ b: B,
        _ c: C,
        _ d: D
    ) throws -> Z {
        try Self.callWithError { error in perform(a, b, c, d, error) }
    }
}
