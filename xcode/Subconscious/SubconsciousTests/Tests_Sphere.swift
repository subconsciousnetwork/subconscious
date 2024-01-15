//
//  Tests_Sphere.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/12/23.
//

import XCTest
@testable import Subconscious

final class Tests_Sphere: XCTestCase {
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
    
    func testRoundtrip() async throws {
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
        
        do {
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            
            try await sphere.write(
                slug: Slug("foo")!,
                contentType: "text/subtext",
                body: "Test".toData(encoding: .utf8)!
            )
            _ = try await sphere.save()
            let memo = try await sphere.read(slashlink: Slashlink("/foo")!)
            XCTAssertEqual(memo.contentType, "text/subtext")
            let content = memo.body.toString()
            XCTAssertEqual(content, "Test")
        }
        
        // Re-open sphere
        do {
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            let memo = try await sphere.read(slashlink: Slashlink("/foo")!)
            XCTAssertEqual(memo.contentType, "text/subtext")
        }
    }
    
    func testHeadersRoundtrip() async throws {
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
        
        let then = Date.distantPast.ISO8601Format()
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            additionalHeaders: [
                Header(name: "Title", value: "Foo"),
                Header(name: "Created", value: then),
                Header(name: "Modified", value: then),
                Header(name: "File-Extension", value: "subtext")
            ],
            body: "Test".toData(encoding: .utf8)!
        )
        _ = try await sphere.save()
        let memo = try await sphere.read(slashlink: Slashlink("/foo")!)
        XCTAssertEqual(memo.contentType, "text/subtext")
        XCTAssertEqual(memo.body.toString(), "Test")
        
        let title = memo.additionalHeaders.get(first: "Title")
        XCTAssertEqual(title, "Foo")
        
        let ext = memo.additionalHeaders.get(first: "File-Extension")
        XCTAssertEqual(ext, "subtext")
        
        let created = memo.additionalHeaders.get(first: "Created")
        XCTAssertEqual(created, then)
        
        let modified = memo.additionalHeaders.get(first: "Created")
        XCTAssertEqual(modified, then)
    }
    
    func testList() async throws {
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
        
        let body = "Test".toData(encoding: .utf8)!
        
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.write(
            slug: Slug("bar")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.write(
            slug: Slug("baz")!,
            contentType: "text/subtext",
            body: body
        )
        
        let slugsA = try await sphere.list()
        XCTAssertEqual(
            slugsA,
            [],
            "Lists all slugs in latest version of sphere"
        )
        
        _ = try await sphere.save()
        
        let slugsB = try await sphere.list()
        XCTAssertTrue(slugsB.contains(Slug("foo")!))
        XCTAssertTrue(slugsB.contains(Slug("bar")!))
        XCTAssertTrue(slugsB.contains(Slug("baz")!))
    }
    
    func testChanges() async throws {
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
        
        let body = "Test".toData(encoding: .utf8)!
        
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        
        let a = try await sphere.save()
        let changesA = try await sphere.changes()
        XCTAssertEqual(changesA.count, 1)
        XCTAssertTrue(changesA.contains(Slug("foo")!))
        
        try await sphere.write(
            slug: Slug("bar")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.write(
            slug: Slug("baz")!,
            contentType: "text/subtext",
            body: body
        )
        let b = try await sphere.save()
        
        let changesB = try await sphere.changes(since: a)
        XCTAssertEqual(changesB.count, 2)
        XCTAssertTrue(changesB.contains(Slug("bar")!))
        XCTAssertTrue(changesB.contains(Slug("baz")!))
        XCTAssertFalse(changesB.contains(Slug("foo")!))
        
        try await sphere.write(
            slug: Slug("bing")!,
            contentType: "text/subtext",
            body: body
        )
        _ = try await sphere.save()
        
        let changesC = try await sphere.changes(since: b)
        XCTAssertEqual(changesC.count, 1)
        XCTAssertTrue(changesC.contains(Slug("bing")!))
        XCTAssertFalse(changesC.contains(Slug("baz")!))
        XCTAssertFalse(changesC.contains(Slug("foo")!))
    }
    
    func testRemove() async throws {
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
        
        let body = "Test".toData(encoding: .utf8)!
        
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: body
        )
        try await sphere.write(
            slug: Slug("bar")!,
            contentType: "text/subtext",
            body: body
        )
        
        _ = try await sphere.save()
        
        try await sphere.remove(slug: Slug("foo")!)
        
        _ = try await sphere.save()
        
        let slugs = try await sphere.list()
        
        XCTAssertEqual(slugs.count, 1)
        XCTAssertTrue(slugs.contains(Slug("bar")!))
        XCTAssertFalse(slugs.contains(Slug("foo")!))
    }
    
    func testSaveVersion() async throws {
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
        
        let versionA = try await sphere.version()
        
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: "Test".toData(encoding: .utf8)!
        )
        
        let version = try await sphere.save()
        
        let versionB = try await sphere.version()
        
        XCTAssertNotEqual(
            versionA,
            versionB,
            "Save updates version"
        )
        
        XCTAssertEqual(
            version,
            versionB,
            "Save returns current version"
        )
    }
    
    func testFailedSync() async throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath,
            gatewayURL: "http://fake-gateway.fake"
        )
        
        let sphereReceipt = try await noosphere.createSphere(
            ownerKeyName: "bob"
        )
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        // Should fail
        _ = try? await sphere.sync()
        
        try await sphere.write(
            slug: Slug("foo")!,
            contentType: "text/subtext",
            body: "Test".toData(encoding: .utf8)!
        )
        
        try await sphere.save()
        
        let foo = try await sphere.read(slashlink: Slashlink("/foo")!)
        
        // Should fail
        _ = try? await sphere.sync()
        
        XCTAssertEqual(
            foo.body.toString(),
            "Test",
            "Read current version"
        )
    }
    
    func testWritesThenCloseThenReopenWithScopes() async throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let sphereIdentity: String
        let startVersion: String
        let endVersion: String
        do {
            let noosphere = try Noosphere(
                globalStoragePath: globalStoragePath,
                sphereStoragePath: sphereStoragePath
            )
            
            let sphereReceipt = try await noosphere.createSphere(
                ownerKeyName: "bob"
            )
            
            sphereIdentity = sphereReceipt.identity
            
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            
            startVersion = try await sphere.version()
            
            let body = try "Test content".toData().unwrap()
            let contentType = "text/subtext"
            try await sphere.write(slug: Slug("a")!, contentType: contentType, body: body)
            try await sphere.write(slug: Slug("b")!, contentType: contentType, body: body)
            try await sphere.write(slug: Slug("c")!, contentType: contentType, body: body)
            let version = try await sphere.save()
            endVersion = try await sphere.version()
            XCTAssertEqual(version, endVersion)
            XCTAssertNotEqual(startVersion, endVersion)
        }
        
        do {
            let noosphere = try Noosphere(
                globalStoragePath: globalStoragePath,
                sphereStoragePath: sphereStoragePath
            )
            
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereIdentity
            )
            let version = try await sphere.version()
            
            XCTAssertEqual(version, endVersion)
        }
    }
    
    func testPetnameRoundtrip() async throws {
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
        let bobName = Petname("bob")!
        
        try await sphere.setPetname(did: bobKey, petname: bobName)
        try await sphere.save()
        
        let bobKey2 = try await sphere.getPetname(petname: bobName)
        XCTAssertEqual(bobKey2, bobKey, "Got back petname")
    }
    
    func testResolvePeer() async throws {
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
        let bobName = Petname("bob")!

        try await sphere.setPetname(did: bobKey, petname: bobName)
        try await sphere.save()

        let did = try await sphere.resolve(peer: .petname(bobName))

        XCTAssertEqual(did, bobKey, "Resolves did")
    }
    
    func testAuthorize() async throws {
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
        
        let did = Did.dummyData()
        
        let authorization = try await sphere.authorize(name: "ben", did: did)
        
        let _ = try await sphere.save()
        
        let authorizations = try await sphere.listAuthorizations()
        XCTAssertEqual(authorizations.count, 2)
        XCTAssertTrue(
            authorizations.contains(where: {
                auth in auth.authorization == authorization && auth.name == "ben"
            })
        )
        
        let name = try await sphere.authorizationName(authorization: authorization)
        XCTAssertEqual(name, "ben")
        
        let verified = try await sphere.verify(authorization: authorization)
        XCTAssertTrue(verified)
        
        let verified2 = try await sphere.verify(authorization: "blah")
        XCTAssertFalse(verified2)
        
        try await sphere.revoke(authorization: authorization)
        
        let _ = try await sphere.save()
        
        let authorizations2 = try await sphere.listAuthorizations()
        XCTAssertEqual(authorizations2.count, 1)
        XCTAssertFalse(authorizations2.contains(where: { auth in auth.authorization == authorization }))
        
    }
}
