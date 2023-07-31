//
//  Tests_OrderedCollectionUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/7/22.
//

import XCTest
import OrderedCollections
@testable import Subconscious
@testable import SubconsciousCore

class Tests_OrderedCollectionUtilities: XCTestCase {
    func testSetDefault() throws {
        var dict: OrderedDictionary<String, String> = [:]
        let value = dict.setDefault("The Gilder", forKey: "Chapter 114")

        XCTAssertEqual(
            dict["Chapter 114"],
            "The Gilder",
            "setDefault sets the default"
        )
        XCTAssertEqual(
            value,
            "The Gilder",
            "returns the value"
        )
    }

    func testSetDefaultDoesNotOverwrite() throws {
        var dict: OrderedDictionary<String, String> = [:]
        dict.updateValue("The Quadrant", forKey: "Chapter 118")
        let value = dict.setDefault("Incorrect", forKey: "Chapter 118")

        XCTAssertEqual(
            dict["Chapter 118"],
            "The Quadrant",
            "setDefault does not overwrite existing keys"
        )
        XCTAssertEqual(
            value,
            "The Quadrant",
            "returns the set value"
        )
    }
}
