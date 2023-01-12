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
        let noosphere = try Noosphere(
            globalStoragePath: "/tmp/foo",
            sphereStoragePath: "/tmp/bar"
        )
        let sphereReceipt = try noosphere.createSphere(ownerKeyName: "bob")
        print("Sphere identity: \(sphereReceipt.identity)")
        print("Sphere mnemonic: \(sphereReceipt.mnemonic)")

        try noosphere.write(
            sphereIdentity: sphereReceipt.identity,
            path: "/foo",
            contentType: "text/subtext",
            contents: "Test".toData(encoding: .utf8)!
        )

        let memo = try noosphere.read(
            sphereIdentity: sphereReceipt.identity,
            path: "/foo"
        )

        XCTAssertEqual(memo.contentType, "text/subtext")
        let content = memo.data.toString(encoding: .utf8)
        XCTAssertEqual(content, "Test")
    }
}
