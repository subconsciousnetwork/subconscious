//
//  Tests_MathUtilities.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 22/11/2023.
//

import XCTest
@testable import Subconscious

class Tests_MathUtilities: XCTestCase {
    func testClamp() {
        var x = 1.5
        XCTAssertEqual(x.clamp(min: 0, max: 1), 1)
        
        x = -1.5
        XCTAssertEqual(x.clamp(min: 0, max: 1), 0)
        
        x = 100000.0
        XCTAssertEqual(x.clamp(min: -100, max: 65), 65)
    }
}
