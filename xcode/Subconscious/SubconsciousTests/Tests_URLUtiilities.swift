//
//  Tests_URLUtiilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/22/23.
//

import XCTest
@testable import Subconscious

final class Tests_URLUtiilities: XCTestCase {
    func testIsHTTP() throws {
        let urlA = URL(string: "http://example.com")!
        XCTAssertTrue(urlA.isHTTP())

        let urlB = URL(string: "https://example.com")!
        XCTAssertTrue(urlB.isHTTP())

        let urlC = URL(string: "ftp://example.com")!
        XCTAssertFalse(urlC.isHTTP())

        let urlD = URL(string: "file://example.com")!
        XCTAssertFalse(urlD.isHTTP())
    }
}
