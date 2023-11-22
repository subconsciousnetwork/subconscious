//
//  Tests_ArrayUtilities.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 22/11/2023.
//

import XCTest
@testable import Subconscious

class Tests_ArrayUtilities: XCTestCase {
    func testRandomInsert() {
        var array = [1, 2, 3, 4, 5]
        array.insertAtRandomIndex(6, skippingFirst: 0)
        XCTAssertTrue(array.contains(6))
    }
    
    func testRandomInsertWithSkip() {
        var array = [1, 2, 3, 4, 5]
        array.insertAtRandomIndex(6, skippingFirst: 2)
        XCTAssertTrue(array.contains(6))
        let idx = array.firstIndex(of: 6)!
        XCTAssertGreaterThan(idx, 1)
    }
    
    func testRandomInsertWithExtremeSkip() {
        var array = [1, 2, 3, 4, 5]
        array.insertAtRandomIndex(6, skippingFirst: 5)
        XCTAssertTrue(array.contains(6))
        let idx = array.firstIndex(of: 6)!
        XCTAssertGreaterThan(idx, 4)
    }
    
    func testRandomInsertWithImpossibleSkip() {
        var array = [1, 2, 3, 4, 5]
        array.insertAtRandomIndex(6, skippingFirst: 50)
        XCTAssertTrue(array.contains(6))
    }
}
