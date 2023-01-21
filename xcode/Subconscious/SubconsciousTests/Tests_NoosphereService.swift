//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/12/23.
//

import XCTest
@testable import Subconscious

final class Tests_Noosphere: XCTestCase {
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
                contents: "Test".toData(encoding: .utf8)!
            )
            sphere.save()
            let memo = try sphere.read(slashlink: "/foo")
            XCTAssertEqual(memo.contentType, "text/subtext")
            let content = memo.body
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
        let noosphere = noosphere!
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")

        let sphere = try Sphere(
            noosphere: noosphere,
            identity: sphereReceipt.identity
        )

        let then = Date.distantPast
        let thenString = then.ISO8601Format()
        try sphere.write(
            slug: "foo",
            contentType: "text/subtext",
            contents: "Test".toData(encoding: .utf8)!,
            additional: [
                Header(name: "Title", value: "Foo"),
                Header(name: "Created", value: thenString),
                Header(name: "Modified", value: thenString),
                Header(name: "File-Extension", value: "subtext")
            ]
        )
        sphere.save()
        let memo = try sphere.read(slashlink: "/foo")
        XCTAssertEqual(memo.contentType, "text/subtext")
        XCTAssertEqual(memo.body, "Test")
        XCTAssertEqual(memo.fileExtension, "subtext")
        XCTAssertEqual(memo.created, then)
        XCTAssertEqual(memo.modified, then)
    }
}
