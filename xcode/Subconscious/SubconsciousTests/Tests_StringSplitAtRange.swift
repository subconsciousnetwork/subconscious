//
//  Tests_StringSplitAtRange.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/2/23.
//

import XCTest
@testable import Subconscious

final class Tests_StringSplitAtRange: XCTestCase {
    func testSplitAtRange() throws {
        let string = "abcdefghijklmnopqrstuvwxyz"
        let range = string.firstRange(of: "defghijklmnopqrstuvw")!
        let (left, right) = string.splitAtRange(range)
        XCTAssertEqual(left, "abc")
        XCTAssertEqual(right, "xyz")
    }
    
    func testSplitAtRangeNSRange() throws {
        let string = "abcdefghijklmnopqrstuvwxyz"
        guard let (left, right) = string.splitAtRange(
            NSRange(location: 3, length: 20)
        ) else {
            XCTFail("Failed to get range from NSRange")
            return
        }
        XCTAssertEqual(left, "abc")
        XCTAssertEqual(right, "xyz")
    }

}
