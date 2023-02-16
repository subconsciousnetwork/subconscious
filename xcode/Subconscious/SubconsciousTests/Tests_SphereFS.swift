//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/12/23.
//

import XCTest
@testable import Subconscious

final class Tests_SphereFS: XCTestCase {
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
    
    func createNoosphere(base: UUID = UUID()) throws -> Noosphere {
        let base = UUID().uuidString

        let globalStoragePath = try createTmpDir(path: "\(base)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(base)/sphere")
            .path()
        
        return try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
    }

    func testRoundtrip() throws {
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        do {
            let sphere = try SphereFS(
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
            let sphere = try SphereFS(
                noosphere: noosphere,
                identity: sphereReceipt.identity
            )
            let memo = try sphere.read(slashlink: "/foo")
            XCTAssertEqual(memo.contentType, "text/subtext")
        }
    }
    
    func testHeadersRoundtrip() throws {
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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
        let noosphere = try createNoosphere()
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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
        let scope = UUID().uuidString

        let globalStoragePath = try createTmpDir(path: "\(scope)/noosphere")
            .path()
        
        let sphereStoragePath = try createTmpDir(path: "\(scope)/sphere")
            .path()
        
        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath,
            gatewayURL: "http://fake-gateway.fake"
        )
        
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        let sphere = try SphereFS(
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

    func testWritesThenCloseThenReopen() throws {
        let uuid = UUID()
        var noosphere = try createNoosphere(base: uuid)
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        
        var sphere = try SphereFS(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        let versionX = try sphere.version()

        let body = try "Test content".toData().unwrap()
        let contentType = "text/subtext"
        try sphere.write(slug: "a", contentType: contentType, body: body)
        try sphere.write(slug: "b", contentType: contentType, body: body)
        try sphere.write(slug: "c", contentType: contentType, body: body)
        let versionY = try sphere.version()

        noosphere = try createNoosphere(base: uuid)
        sphere = try SphereFS(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )
        let versionZ = try sphere.version()

        XCTAssertEqual(versionY, versionZ)
    }
}
