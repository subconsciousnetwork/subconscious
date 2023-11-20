//
//  Tests_ArrayChanges.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/20/23.
//

import XCTest
@testable import Subconscious

final class Tests_ArrayChanges: XCTestCase {
    struct Item: Hashable, Identifiable {
        var id = UUID()
        var text: String
    }
    
    func testDiff() throws {
        let a = Item(text: "A")
        let b = Item(text: "B")
        let c = Item(text: "C")
        let d = Item(text: "D")
        let z = Item(text: "Z")
        
        let prev = [
            a,
            b,
            c,
            d
        ]
        var b2 = b
        b2.text = "BBB"
        let next = [
            a,
            c,
            b2,
            z,
            d
        ]
        let diff = next.changes(from: prev)
        XCTAssert(diff.contains(.updated(index: 2, element: b2)))
        XCTAssert(diff.contains(.added(index: 3, element: z)))
    }
}
