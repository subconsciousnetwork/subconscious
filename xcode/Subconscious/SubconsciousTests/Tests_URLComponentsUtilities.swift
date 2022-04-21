//
//  Tests_URLUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/21/22.
//

import XCTest
@testable import Subconscious

class Tests_URLComponentsUtilities: XCTestCase {
    func testfirstQueryItemWhere() throws {
        guard let components = URLComponents(
            string: "http://example.com?foo=bar&baz=bing"
        ) else {
            XCTFail("Expected URLComponents")
            return
        }

        let item = components.firstQueryItemWhere(name: "foo")
        XCTAssertEqual(
            item?.value,
            "bar",
            "Gets query item matching name"
        )
    }

    func testfirstQueryItemWhereDupe() throws {
        guard let components = URLComponents(
            string: "http://example.com?foo=bar&baz=bing&foo=nope"
        ) else {
            XCTFail("Expected URLComponents")
            return
        }

        let item = components.firstQueryItemWhere(name: "foo")
        XCTAssertEqual(
            item?.value,
            "bar",
            "Gets first query item matching name"
        )
    }

    func testReturnsNilForMissingItem() throws {
        guard let components = URLComponents(
            string: "http://example.com?foo=bar&baz=bing&foo=nope"
        ) else {
            XCTFail("Expected URLComponents")
            return
        }

        let foo = components.firstQueryItemWhere(name: "boing")
        XCTAssertEqual(
            foo?.value,
            nil,
            "Returns nil for missing query item"
        )
    }
}
