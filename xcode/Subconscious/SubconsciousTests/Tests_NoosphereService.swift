//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/16/23.
//

import XCTest
@testable import Subconscious

final class Tests_NoosphereService: XCTestCase {
    /// Create a unique temp dir and return URL
    static func createTmpDir(_ path: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(
            path: path,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    func testNoosphereReset() throws {
        let base = UUID()
        
        let globalStorageURL = try Self.createTmpDir("\(base)/noosphere")
        let sphereStorageURL = try Self.createTmpDir("\(base)/sphere")

        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL
        )

        let receipt = try noosphere.createSphere(ownerKeyName: "bob")
        noosphere.resetSphere(receipt.identity)

        let versionA = try noosphere.version()
        
        let body = try "Test content".toData().unwrap()
        try noosphere.write(
            slug: "a",
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        let versionB = try noosphere.save()
        XCTAssertNotEqual(versionA, versionB)

        try noosphere.write(
            slug: "b",
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        try noosphere.write(
            slug: "c",
            contentType: "text/subtext",
            additionalHeaders: [],
            body: body
        )
        let versionC = try noosphere.save()
        XCTAssertNotEqual(versionB, versionC)

        // Clear out Noosphere and Sphere instance
        noosphere.reset()

        let versionZ = try noosphere.version()
        XCTAssertEqual(versionC, versionZ)
    }
}
