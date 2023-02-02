//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/12/23.
//

import XCTest
@testable import Subconscious

final class Tests_Sphere: XCTestCase {
    var noosphere: Noosphere?
    
    override func setUpWithError() throws {
        let globalStoragePath = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "noosphere",
                isDirectory: true
            )
            .path()
        print("Noosphere global storage path: \(globalStoragePath)")
        
        let sphereStoragePath = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "sphere",
                isDirectory: true
            )
            .path()
        print("Noosphere sphere storage path: \(sphereStoragePath)")
        
        self.noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
    }
    
    func testRoundtrip() throws {
        let noosphere = noosphere!
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        print("Sphere identity: \(sphereReceipt.identity)")
        print("Sphere mnemonic: \(sphereReceipt.mnemonic)")
        
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
            guard let memo = sphere.read(slashlink: "/foo") else {
                XCTFail("Could not read memo")
                return
            }
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
            guard let memo = sphere.read(slashlink: "/foo") else {
                XCTFail("Could not read memo")
                return
            }
            XCTAssertEqual(memo.contentType, "text/subtext")
        }
    }
    
    func testHeadersRoundtrip() throws {
        let noosphere = noosphere!
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
        guard let memo = sphere.read(slashlink: "/foo") else {
            XCTFail("Could not read memo")
            return
        }
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
        let noosphere = noosphere!
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
        let noosphere = noosphere!
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
        _ = try sphere.save()
        
        let changesB = try sphere.changes(a)
        XCTAssertEqual(changesB.count, 2)
        XCTAssertTrue(changesB.contains("bar"))
        XCTAssertTrue(changesB.contains("baz"))
        XCTAssertFalse(changesB.contains("foo"))
    }

    func testRemove() throws {
        let noosphere = noosphere!
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
        let noosphere = noosphere!
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
}
