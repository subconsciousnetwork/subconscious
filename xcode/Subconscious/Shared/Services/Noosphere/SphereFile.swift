//
//  SphereFile.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/20/23.
//

import Foundation
import SwiftNoosphere

/// Describes a Sphere file.
/// See `SphereFile` for a concrete implementation.
public protocol SphereFileProtocol {
    func version() async throws -> String
    
    func readHeaderValueFirst(
        name: String
    ) async throws -> String?
    
    func readHeaderNames() async throws -> [String]
    
    func consumeContents() async throws -> Data
}

enum SphereFileError: Error {
    case consumed
}

/// Wrapper for sphere file.
/// Will automatically free sphere file pointer when class de-initializes.
actor SphereFile: SphereFileProtocol {
    private var isConsumed = false
    private let noosphere: Noosphere
    let file: OpaquePointer
    
    init?(
        noosphere: Noosphere,
        file: OpaquePointer?
    ) {
        guard let file = file else {
            return nil
        }
        self.noosphere = noosphere
        self.file = file
    }
    
    /// Get the base64-encoded CID v1 string for the memo that refers to the
    /// content of this sphere file.
    /// - Returns CID string, if any
    public func version() throws -> String {
        guard !isConsumed else {
            throw SphereFileError.consumed
        }
        guard let cid = try Noosphere.callWithError(
            ns_sphere_file_version_get,
            self.file
        ) else {
            throw NoosphereError.nullPointer
        }
        defer {
            ns_string_free(cid)
        }
        return String(cString: cid)
    }
    
    /// Read first header value for memo at slashlink
    /// - Returns: value, if any
    public func readHeaderValueFirst(
        name: String
    ) throws -> String? {
        guard !isConsumed else {
            throw SphereFileError.consumed
        }
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
    
    public func readHeaderNames() async throws -> [String] {
        guard !isConsumed else {
            throw SphereFileError.consumed
        }
        let file_header_names = ns_sphere_file_header_names_read(self.file)
        defer {
            ns_string_array_free(file_header_names)
        }
        return file_header_names.toStringArray()
    }
    
    public func consumeContents() async throws -> Data {
        guard !isConsumed else {
            throw SphereFileError.consumed
        }
        self.isConsumed = true
        return try await withCheckedThrowingContinuation { continuation in
            nsSphereFileContentsRead(
                self.noosphere.noosphere,
                self.file
            ) { error, contents in
                if let message = Noosphere.readErrorMessage(error) {
                    continuation.resume(
                        throwing: NoosphereError.foreignError(message)
                    )
                    return
                }
                let data = Data(bytes: contents.ptr, count: contents.len)
                continuation.resume(returning: data)
            }
            return
        }
    }
    
    deinit {
        // Free pointer if content was not read.
        // Note that Noosphere frees the pointer automatically *IF* the
        // content has been read. We use the `isConsumed` flag to track this
        // state and manually free the pointer ourselves **ONLY IF* the
        // content was not read.
        guard isConsumed else {
            ns_sphere_file_free(file)
            return
        }
    }
}

