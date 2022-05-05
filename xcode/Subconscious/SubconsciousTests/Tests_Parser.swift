//
//  Tests_HeaderParser.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/5/22.
//

import XCTest
@testable import Subconscious

class Tests_Parser: XCTestCase {
    func testAdvance() throws {
        let state = Parser.ParseState(rest: "abcdefg")
        let next = Parser.advance(state)
        XCTAssertEqual(next.token, "a")
        XCTAssertEqual(next.rest, "bcdefg")
    }

    func testParseUntilMatch() throws {
        let state = Parser.ParseState(rest: "abcdefg")
        let next = Parser.parseUntil(state, match: { char in
            char == "d"
        })
        XCTAssertEqual(next.token, "abc")
        XCTAssertEqual(next.rest, "defg")
    }

    func testParseHeaderName() throws {
        let result = Parser.parseHeaderName(
            Parser.ParseState(
                rest: "Content-Type:"
            )
        )!
        XCTAssertEqual(
            String(result.token),
            "Content-Type"
        )
    }

    func testParseHeaderValue() throws {
        let result = Parser.parseHeaderValue(
            Parser.ParseState(
                rest: "Four score and seven years ago\n"
            )
        )!
        XCTAssertEqual(
            String(result.token),
            "Four score and seven years ago"
        )
    }

    func testParseHeader() throws {
        let result = Parser.parseHeader(
            "Content-Type: text/subtext\n"
        )!
        XCTAssertEqual(
            String(result.token.name),
            "content-type"
        )
        XCTAssertEqual(
            String(result.token.value),
            "text/subtext"
        )
    }

    func testParseInvalidHeaderName() throws {
        let result = Parser.parseHeader(
            "Content Type: text/subtext\n"
        )
        XCTAssertEqual(
            result,
            nil
        )
    }

    func testParseHeaderEOL() throws {
        let result = Parser.parseHeader(
            "Content-Type: text/subtext"
        )!
        XCTAssertEqual(
            result.token.value,
            "text/subtext"
        )
    }

    func testParseHeaders() throws {
        let result = Parser.parseHeaders(
            "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        )
        XCTAssertEqual(
            result.token[0].name,
            "content-type"
        )
        XCTAssertEqual(
            result.token[1].name,
            "title"
        )
        XCTAssertEqual(
            result.rest,
            "Body text\n"
        )
    }

    func testParseNoHeaders() throws {
        let result = Parser.parseHeaders(
            "\nBody text\n"
        )
        XCTAssertEqual(
            result.token.count,
            0
        )
        XCTAssertEqual(
            result.rest,
            "Body text\n"
        )
    }

    func testParseMissingHeaders() throws {
        let result = Parser.parseHeaders(
            "Body text\n"
        )
        XCTAssertEqual(
            result.token.count,
            0
        )
        XCTAssertEqual(
            result.rest,
            "Body text\n"
        )
    }
}
