//
//  Tests_NoosphereService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/12/23.
//

import XCTest
@testable import Subconscious

final class Tests_NoosphereService: XCTestCase {
    func testRoundtrip() throws {
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

        let noosphere = try Noosphere(
            globalStoragePath: globalStoragePath,
            sphereStoragePath: sphereStoragePath
        )
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
}
