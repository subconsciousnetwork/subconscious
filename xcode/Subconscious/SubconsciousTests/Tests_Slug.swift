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

    func testFormat() throws {
        let a = Slug.format(
            "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            a,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
        let b = Slug.format("The_quick_Brown_fOx")
        XCTAssertEqual(
            b,
            "the_quick_brown_fox",
            "Underscores allowed"
        )
        let c = Slug.format("the/quick brown/fox jumps")
        XCTAssertEqual(
            c,
            "the/quick-brown/fox-jumps",
            "Formats deep slug string into a valid slug-string"
        )
        let d = Slug.format("the QuIck brown FOX ")
        XCTAssertEqual(
            d,
            "the-quick-brown-fox",
            "Trims string before sluggifying"
        )
        let e = Slug.format("the QuIck brown FOX !$%")
        XCTAssertEqual(
            e,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
    }

    func testToSentence() throws {
        let sentence = Slug("frozen-yogurt")?.toSentence()
        XCTAssertEqual(
            sentence,
            "Frozen yogurt",
            "Sentenc-ifies slug and capitalizes first letter"
        )
    }
}
