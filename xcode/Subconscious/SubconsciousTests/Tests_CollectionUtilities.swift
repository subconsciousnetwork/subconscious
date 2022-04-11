//
//  Tests_CollectionUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/11/22.
//

import XCTest
@testable import Subconscious

class Tests_CollectionUtilities: XCTestCase {

    func testCollectionGetValidBounds() throws {
        let collection = [0, 1, 2, 3]
        let value = collection.get(1)
        XCTAssertEqual(
            value,
            1,
            "Collection.get retreives value at index within valid bounds"
        )
    }

    func testCollectionGetInValidBounds() throws {
        let collection = [0, 1, 2, 3]
        let value = collection.get(1000)
        XCTAssertEqual(
            value,
            nil,
            "Collection.get returns nil for index outside of valid bounds"
        )
    }

    func testCollectionEmpty() throws {
        let collection: [Int] = []
        let value = collection.get(0)
        XCTAssertEqual(
            value,
            nil,
            "Collection.get returns nil for index outside of valid bounds"
        )
    }
}
