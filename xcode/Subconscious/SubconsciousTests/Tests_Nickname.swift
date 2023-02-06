//
//  Tests_Slug.swift
//  Tests iOS
//
//  Created by Gordon Brander on 3/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Nickname: XCTestCase {
    func testStrictValidSlugConstruction() throws {
        let string = "valid-strict-nickname"
        XCTAssertNotNil(
            Nickname(string),
            "Nickname created from valid string"
        )
    }

    func testStrictInvalidSlugConstruction() throws {
        let string = "Inv@lid nickname 😆"
        XCTAssertNil(
            Nickname(string),
            "Invalid string is rejected"
        )
    }

    func testStrictValidSlugLosslessStringConvertable() throws {
        let string = "valid-strict-nickname"
        XCTAssertEqual(
            Nickname(string)?.description,
            string,
            "LosslessStringConvertable for valid strings"
        )
    }

    func testFormatStripsInvalidCharacters() throws {
        let string = Nickname.format(
            "The quick brown fox jumps over the lazy dog!@#$%^&*()+,>:;'|{}[]<>?"
        )
        XCTAssertEqual(
            string,
            "the-quick-brown-fox-jumps-over-the-lazy-dog",
            "Formats the string into a valid nickname string"
        )
    }

    func testFormatUnicodeCharacters0() throws {
        // Note the apostrophe-like character here is a word character
        let nickname = Nickname(
            formatting: "Baháʼí"
        )
        XCTAssertEqual(
            String(nickname),
            "baháʼí"
        )
    }

    func testFormatUnicodeCharacters1() throws {
        let nickname = Nickname(
            formatting: "Fédération Aéronautique Internationale"
        )
        XCTAssertEqual(
            String(nickname),
            "fédération-aéronautique-internationale"
        )
    }

    func testFormatLeavesUnderscoresIntact() throws {
        let nickname = Nickname.format("The_quick_Brown_fOx")
        XCTAssertEqual(
            nickname,
            "the_quick_brown_fox",
            "Underscores allowed"
        )
    }

    func testFormatTrimsEndOfString() throws {
        let nickname = Nickname.format("the QuIck brown FOX ")
        XCTAssertEqual(
            nickname,
            "the-quick-brown-fox",
            "Trims string before formatting"
        )
    }

    func testFormatTrimsStringAfterRemovingInvalidCharacters() throws {
        let nickname = Nickname.format("the QuIck brown FOX !$%")
        XCTAssertEqual(
            nickname,
            "the-quick-brown-fox",
            "Trims string after stripping characters"
        )
    }

    func testFormatTrimsNonAllowedAndWhitespaceBeforeSlashes() throws {
        let nickname = Nickname.format("  /the QuIck brown FOX/ !$%")
        XCTAssertEqual(
            nickname,
            "the-quick-brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }

    func testFormatCollapsesContiguousWhitespace() throws {
        let nickname = Nickname.format("  /the QuIck      brown FOX")
        XCTAssertEqual(
            nickname,
            "the-quick------brown-fox",
            "Trims non-allowed characters and whitespace before slashes"
        )
    }
}
