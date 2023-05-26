//
//  Tests_Sphere+Link.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/4/23.
//

import XCTest
@testable import Subconscious

final class Tests_Sphere_Link: XCTestCase {
    /// Create a unique temp dir and return URL
    func createTmpDir(path: String) throws -> URL {
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

    func testResolve() async throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try await noosphere.createSphere(
            ownerKeyName: "bob"
        )
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let bobKey = Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!
        let bobName = Petname.Name("bob")!
        
        try await sphere.setPetname(did: bobKey, petname: bobName)
        try await sphere.save()
        
        let slug = Slug("foo")!
        
        let relBob = Slashlink(
            peer: .petname(bobName.toPetname()),
            slug: slug
        )
        
        let linkBob = try await sphere.resolveLink(slashlink: relBob)
        
        XCTAssertEqual(linkBob.did, bobKey, "Correct key retreived")
        XCTAssertEqual(linkBob.slug, slug, "Slug remains unchanged")
    }
}
