//
//  Tests_CollectionUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/11/22.
//

import XCTest
@testable import Subconscious

class Tests_CollectionUtilities: XCTestCase {
    func testUniquing() throws {
        let array = [1, 2, 1, 2, 3, 3, 1, 4]
        let unique = array.uniquing(with: { i in i })
        XCTAssertEqual(unique.count, 4)
        XCTAssertEqual(unique[0], 1)
        XCTAssertEqual(unique[1], 2)
        XCTAssertEqual(unique[2], 3)
        XCTAssertEqual(unique[3], 4)
    }
}
