//
//  Tests_HeaderParser.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/5/22.
//

import XCTest
@testable import Subconscious

class Tests_Parser: XCTestCase {
    func testParseHeaderName() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Parser.parseHeaderName(&tape)
        XCTAssertEqual(
            header,
            "Content-Type"
        )
    }

    func testParseHeaderValue() throws {
        var tape = Tape("abcdefg\n")
        let value = Parser.parseHeaderValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testParseHeaderValueEOL() throws {
        var tape = Tape("abcdefg")
        let value = Parser.parseHeaderValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testParseHeader() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Parser.parseHeader(&tape)
        XCTAssertEqual(
            header!.name,
            "content-type"
        )
    }

    func testParseHeaderMalformed() throws {
        let doc = "Malformed header: You ganked my spirit walker\n"
        var tape = Tape(doc[...])
        let header = Parser.parseHeader(&tape)
        XCTAssertEqual(
            header,
            nil
        )
    }

    func testHeadersParser() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let headers = Parser.parseHeaders(&tape)
        XCTAssertEqual(
            headers.headers[0].name,
            "content-type"
        )
        XCTAssertEqual(
            headers.headers[1].name,
            "title"
        )
        XCTAssertEqual(
            headers.headers[1].value,
            "Floop the Pig"
        )
    }

    func testParseNoHeaders() throws {
        var tape = Tape("\nBody text\n")
        let result = Parser.parseHeaders(&tape)
        XCTAssertEqual(
            result.headers.count,
            0
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testParseMissingHeaders() throws {
        var tape = Tape("Body text\n")
        let result = Parser.parseHeaders(&tape)
        XCTAssertEqual(
            result.headers.count,
            0
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testParseInvalidHeaderName() throws {
        var tape = Tape("Content Type: text/subtext\n")
        let result = Parser.parseHeader(&tape)
        XCTAssertEqual(
            result,
            nil
        )
    }

    func testParseHeaderEOL() throws {
        var tape = Tape("Content-Type: text/subtext")
        let result = Parser.parseHeader(&tape)!
        XCTAssertEqual(
            result.value,
            "text/subtext"
        )
    }

    func testParseLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Title: Cybernetic self-systems
            
            Body text
            """
        )
        let header = Parser.parseLine(&tape)
        XCTAssertEqual(header, "Content-Type: text/subtext\n")

        let title = Parser.parseLine(&tape)
        XCTAssertEqual(title, "Title: Cybernetic self-systems\n")

        let blank = Parser.parseLine(&tape)
        XCTAssertEqual(blank, "\n")

        let body = Parser.parseLine(&tape)
        XCTAssertEqual(body, "Body text")
    }
}
