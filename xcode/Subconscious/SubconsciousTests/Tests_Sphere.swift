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
    
    func testRoundtrip() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        do {
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            
            try sphere.write(
                slug: "foo",
                contentType: "text/subtext",
                body: "Test".toData(encoding: .utf8)!
            )
            _ = try sphere.save()
            let memo = try sphere.read(slashlink: "/foo")
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
            let memo = try sphere.read(slashlink: "/foo")
            XCTAssertEqual(memo.contentType, "text/subtext")
        }
    }
    
    func testHeadersRoundtrip() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let then = Date.distantPast.ISO8601Format()
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            additionalHeaders: [
                Header(name: "Title", value: "Foo"),
                Header(name: "Created", value: then),
                Header(name: "Modified", value: then),
                Header(name: "File-Extension", value: "subtext")
            ],
            body: "Test".toData(encoding: .utf8)!
        )
        _ = try sphere.save()
        let memo = try sphere.read(slashlink: "/foo")
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
    
    func testList() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let body = "Test".toData(encoding: .utf8)!
        
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            body: body
        )
        try sphere.write(
            slug: "bar",
            contentType: "text/subtext",
            body: body
        )
        try sphere.write(
            slug: "baz",
            contentType: "text/subtext",
            body: body
        )
        
        let slugsA = try sphere.list()
        XCTAssertEqual(
            slugsA,
            [],
            "Lists all slugs in latest version of sphere"
        )
        
        _ = try sphere.save()
        
        let slugsB = try sphere.list()
        XCTAssertTrue(slugsB.contains("foo"))
        XCTAssertTrue(slugsB.contains("bar"))
        XCTAssertTrue(slugsB.contains("baz"))
    }
    
    func testChanges() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let body = "Test".toData(encoding: .utf8)!
        
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            body: body
        )
        
        let a = try sphere.save()
        let changesA = try sphere.changes()
        XCTAssertEqual(changesA.count, 1)
        XCTAssertTrue(changesA.contains("foo"))
        
        try sphere.write(
            slug: "bar",
            contentType: "text/subtext",
            body: body
        )
        try sphere.write(
            slug: "baz",
            contentType: "text/subtext",
            body: body
        )
        let b = try sphere.save()
        
        let changesB = try sphere.changes(a)
        XCTAssertEqual(changesB.count, 2)
        XCTAssertTrue(changesB.contains("bar"))
        XCTAssertTrue(changesB.contains("baz"))
        XCTAssertFalse(changesB.contains("foo"))
        
        try sphere.write(
            slug: "bing",
            contentType: "text/subtext",
            body: body
        )
        _ = try sphere.save()
        
        let changesC = try sphere.changes(b)
        XCTAssertEqual(changesC.count, 1)
        XCTAssertTrue(changesC.contains("bing"))
        XCTAssertFalse(changesC.contains("baz"))
        XCTAssertFalse(changesC.contains("foo"))
    }
    
    func testRemove() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let body = "Test".toData(encoding: .utf8)!
        
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            body: body
        )
        try sphere.write(
            slug: "bar",
            contentType: "text/subtext",
            body: body
        )
        
        _ = try sphere.save()
        
        try sphere.remove(slug: "foo")
        
        _ = try sphere.save()
        
        let slugs = try sphere.list()
        
        XCTAssertEqual(slugs.count, 1)
        XCTAssertTrue(slugs.contains("bar"))
        XCTAssertFalse(slugs.contains("foo"))
    }
    
    func testSaveVersion() throws {
        let base = UUID()
        
        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        let versionA = try sphere.version()
        
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            body: "Test".toData(encoding: .utf8)!
        )
        
        let version = try sphere.save()
        
        let versionB = try sphere.version()
        
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
    
    func testFailedSync() throws {
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
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        
        // Should fail
        _ = try? sphere.sync()
        
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            body: "Test".toData(encoding: .utf8)!
        )
        
        try sphere.save()
        
        let foo = try sphere.read(slashlink: "/foo")
        
        // Should fail
        _ = try? sphere.sync()
        
        XCTAssertEqual(
            foo.body.toString(),
            "Test",
            "Read current version"
        )
    }
    
    func testWritesThenCloseThenReopenWithScopes() throws {
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
            
            let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
            
            sphereIdentity = sphereReceipt.identity
            
            let sphere = try Sphere(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            
            startVersion = try sphere.version()
            
            let body = try "Test content".toData().unwrap()
            let contentType = "text/subtext"
            try sphere.write(slug: "a", contentType: contentType, body: body)
            try sphere.write(slug: "b", contentType: contentType, body: body)
            try sphere.write(slug: "c", contentType: contentType, body: body)
            let version = try sphere.save()
            endVersion = try sphere.version()
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
            let version = try sphere.version()
            
            XCTAssertEqual(version, endVersion)
        }
    }
    
    func testWritesThenCloseThenReopenWithVars() throws {
        let base = UUID()

        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        var noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )

        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphereIdentity = sphereReceipt.identity

        var sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )

        let versionA0 = try sphere.version()

        let body = try "Test content".toData().unwrap()
        let contentType = "text/subtext"
        try sphere.write(slug: "a", contentType: contentType, body: body)

        let versionA1 = try sphere.save()

        try sphere.write(slug: "b", contentType: contentType, body: body)
        try sphere.write(slug: "c", contentType: contentType, body: body)
        let versionA2 = try sphere.save()

        let versionAN = try sphere.version()

        XCTAssertNotEqual(versionA0, versionAN)
        XCTAssertNotEqual(versionA1, versionAN)
        XCTAssertEqual(versionA2, versionAN)

        // Overwrite var with new instance
        noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
        // Overwrite sphere with new sphere
        sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereIdentity
        )
        let versionB0 = try sphere.version()

        XCTAssertEqual(versionB0, versionAN)
    }
}
