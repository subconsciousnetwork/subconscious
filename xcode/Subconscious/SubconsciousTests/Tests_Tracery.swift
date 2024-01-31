//
//  Tests_Tracery.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 1/30/24.
//

import XCTest
@testable import Subconscious

final class Tests_Tracery: XCTestCase {
    func testMaxRecursionDepthExceeded() throws {
        let tracery = Tracery()
        _ = tracery.flatten(
            grammar: [
                "foo": ["foo #bar#"],
                "bar": ["bar #foo#"]
            ]
        )
        XCTAssertTrue(true, "Recursive grammars stop flattening after a certain depth")
    }
}
