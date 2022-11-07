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

    func testSlugFromPathlike() throws {
        let pathlikeA = "foo.subtext"

        XCTAssertEqual(
            Slug(fromPath: pathlikeA, withExtension: "subtext"),
            Slug("foo")!
        )

        let pathlikeB = "foo/bar.subtext"
        XCTAssertEqual(
            Slug(fromPath: pathlikeB, withExtension: "subtext"),
            Slug("foo/bar")!
        )

        let pathlikeC = "foo/bar.txt"
        XCTAssertNil(
            Slug(fromPath: pathlikeC, withExtension: "subtext"),
            "Returns nil for invalid path extension"
        )
    }

    func testFormatStripsInvalidCharacters() throws {
        let slug = Slug.format(
            "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            slug,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid slug-string"
        )
    }

    func testFormatUnicodeCharacters0() throws {
        guard let slug = Slug(
            formatting: "Baháʼí"
        ) else {
            XCTFail("Expected Slug")
            return
        }
        XCTAssertEqual(
            String(slug),
            "bah"
        )
    }

    func testFormatUnicodeCharacters1() throws {
        guard let slug = Slug(
            formatting: "Fédération Aéronautique Internationale"
        ) else {
            XCTFail("Expected Slug")
            return
        }
        XCTAssertEqual(
            String(slug),
            "fdration-aronautique-internationale"
        )
    }

    func testFormatLeavesUnderscoresIntact() throws {
        let slug = Slug.format("The_quick_Brown_fOx")
        XCTAssertEqual(
            slug,
            "the_quick_brown_fox",
            "Underscores allowed"
        )
    }

    func testFormatRespectsDeepSlashes() throws {
        let slug = Slug.format("the/quick brown/fox jumps")
        XCTAssertEqual(
            slug,
            "the/quick-brown/fox-jumps",
            "Formats deep slug string into a valid slug-string"
        )
    }

    func testFormatTrimsEndOfString() throws {
        let slug = Slug.format("the QuIck brown FOX ")
        XCTAssertEqual(
            slug,
            "the-quick-brown-fox",
            "Trims string before sluggifying"
        )
    }

    func testFormatTrimsStringAfterRemovingInvalidCharacters() throws {
        let slug = Slug.format("the QuIck brown FOX !$%")
        XCTAssertEqual(
            slug,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
    }

    func testFormatTrimsNonAllowedAndWhitespaceBeforeSlashes() throws {
        let slug = Slug.format("  /the QuIck brown FOX/ !$%")
        XCTAssertEqual(
            slug,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }

    func testFormatCollapsesContiguousWhitespace() throws {
        let slug = Slug.format("  /the QuIck      brown FOX")
        XCTAssertEqual(
            slug,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }

    func testToTitle() throws {
        let title = Slug("frozen-yogurt")!.toTitle()
        XCTAssertEqual(
            title,
            "Frozen yogurt",
            "Title-ifies slug and capitalizes first letter"
        )
    }
}
