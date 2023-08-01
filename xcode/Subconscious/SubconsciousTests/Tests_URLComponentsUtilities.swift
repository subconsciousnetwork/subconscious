//
//  Tests_URLUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/21/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

class Tests_URLComponentsUtilities: XCTestCase {
    func testfirstQueryValueWhere() throws {
        guard let components = URLComponents(
            string: "http://example.com?foo=bar&baz=bing"
        ) else {
            XCTFail("Expected URLComponents")
            return
        }

        let item = components.firstQueryValueWhere(name: "foo")
        XCTAssertEqual(
            item,
            "bar",
            "Gets query item matching name"
        )
    }

    func testfirstQueryValueWhereDupe() throws {
        guard let components = URLComponents(
            string: "http://example.com?foo=bar&baz=bing&foo=nope"
        ) else {
            XCTFail("Expected URLComponents")
            return
        }

        let item = components.firstQueryValueWhere(name: "foo")
        XCTAssertEqual(
            item,
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

        let foo = components.firstQueryValueWhere(name: "boing")
        XCTAssertEqual(
            foo,
            nil,
            "Returns nil for missing query item"
        )
    }
}
