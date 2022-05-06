//
//  Tests_Header.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/6/22.
//

import XCTest
@testable import Subconscious

class Tests_Header: XCTestCase {
    func testParseHeaderName() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Header.parseName(&tape)
        XCTAssertEqual(
            header,
            "Content-Type"
        )
    }

    func testParseHeaderValue() throws {
        var tape = Tape("abcdefg\n")
        let value = Header.parseValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testParseHeaderValueEOL() throws {
        var tape = Tape("abcdefg")
        let value = Header.parseValue(&tape)
        XCTAssertEqual(
            value,
            "abcdefg"
        )
    }

    func testParseHeader() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let header = Header.parse(&tape)
        XCTAssertEqual(
            header!.name,
            "content-type"
        )
    }

    func testParseHeaderMalformed() throws {
        let doc = "Malformed header: You ganked my spirit walker\n"
        var tape = Tape(doc[...])
        let header = Header.parse(&tape)
        XCTAssertEqual(
            header,
            nil
        )
    }

    func testParseInvalidHeaderName() throws {
        var tape = Tape("Content Type: text/subtext\n")
        let result = Header.parse(&tape)
        XCTAssertEqual(
            result,
            nil
        )
    }

    func testParseHeaderEOL() throws {
        var tape = Tape("Content-Type: text/subtext")
        let result = Header.parse(&tape)!
        XCTAssertEqual(
            result.value,
            "text/subtext"
        )
    }

    func testHeadersParser() throws {
        let doc = "Content-Type: text/subtext\nMalformed header: Husker knights\nTitle: Floop the Pig\n\nBody text\n"
        var tape = Tape(doc[...])
        let headers = Headers.parse(&tape)
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
        XCTAssertEqual(
            headers.body,
            "Body text\n"
        )
    }

    func testParseNoHeaders() throws {
        var tape = Tape("\nBody text\n")
        let headers = Headers.parse(&tape)
        XCTAssertEqual(
            headers.headers.count,
            0
        )
        XCTAssertEqual(
            headers.body,
            "Body text\n"
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testParseMissingHeaders() throws {
        var tape = Tape("Body text\n")
        let headers = Headers.parse(&tape)
        XCTAssertEqual(
            headers.headers.count,
            0
        )
        XCTAssertEqual(
            headers.body,
            "Body text\n"
        )
        XCTAssertEqual(
            tape.rest,
            "Body text\n"
        )
    }

    func testHeadersFirst() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Content-Type: text/plain
            Title: Floop the Pig

            Body text
            """
        )
        let headers = Headers.parse(&tape)
        let header = headers.first(named: "content-type")
        XCTAssertNotNil(header)
        XCTAssertEqual(header!.value, "text/subtext")
    }

    func testHeadersRender() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Content-Type: text/plain
            Title: Floop the Pig

            Body text
            """
        )
        let headers = Headers.parse(&tape)
        let text = headers.render()
        XCTAssertEqual(
            text,
            """
            Content-Type: text/subtext
            Content-Type: text/plain
            Title: Floop the Pig

            Body text
            """,
            "Renders headers, dropping malformed headers"
        )
    }
}
