//
//  Tests_Slug.swift
//  Tests iOS
//
//  Created by Gordon Brander on 3/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Slug: XCTestCase {
    func testStrictValidSlugConstruction() throws {
        let slugString = "valid-strict-slug"
        XCTAssertNotNil(
            Slug(slugString),
            "Slug created from valid slug string"
        )
    }

    func testStrictInvalidSlugConstruction() throws {
        let slugString = "Inv@led slug 😆"
        XCTAssertNil(
            Slug(slugString),
            "Invalid slug string is rejected by strict constructor"
        )
    }

    func testStrictValidSlugLosslessStringConvertable() throws {
        let slugString = "valid-strict-slug"
        XCTAssertEqual(
            Slug(slugString)?.description,
            slugString,
            "slug is LosslessStringConvertable for valid slug strings"
        )
    }
}
