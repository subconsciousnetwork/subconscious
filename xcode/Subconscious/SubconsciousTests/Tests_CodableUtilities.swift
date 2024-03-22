//
//  Tests_CodableUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/11/24.
//

import XCTest
@testable import Subconscious

final class Tests_CodableUtilities: XCTestCase {
    struct Vec2D: Hashable, Codable {
        let x: Float
        let y: Float
    }

    struct Rectangle: Hashable, Codable {
        let coords: Vec2D
        let width: Float
        let height: Float
    }

    func testStringify() throws {
        let rect = Rectangle(
            coords: Vec2D(x: 0, y: 0),
            width: 100,
            height: 100
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let string = try encoder.stringify(rect)

        XCTAssertEqual(string, #"{"coords":{"x":0,"y":0},"height":100,"width":100}"#)
    }

    func testParse() throws {
        let json = #"{"height":100,"width":100,"coords":{"x":0,"y":0}}"#

        let decoder = JSONDecoder()
        let rect = try decoder.parse(Rectangle.self, string: json)

        XCTAssertEqual(rect, Rectangle(
            coords: Vec2D(x: 0, y: 0),
            width: 100,
            height: 100
        ))
    }

    func testRoundtrip() throws {
        let rect = Rectangle(
            coords: Vec2D(x: 0, y: 0),
            width: 100,
            height: 100
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let string = try encoder.stringify(rect)

        let decoder = JSONDecoder()
        let rect2 = try decoder.parse(Rectangle.self, string: string)

        XCTAssertEqual(rect, rect2)
    }
}
