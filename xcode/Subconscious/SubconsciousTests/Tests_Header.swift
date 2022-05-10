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
            header!.normalizedName,
            "Content-Type"
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
            headers.headers[0].normalizedName,
            "Content-Type"
        )
        XCTAssertEqual(
            headers.headers[1].normalizedName,
            "Title"
        )
        XCTAssertEqual(
            headers.headers[1].value,
            "Floop the Pig"
        )
    }

    func testParseHeadersDropsEmptyLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Title: Floop the Pig
            
            Body text
            """
        )
        let headers = Headers.parse(&tape)
        XCTAssertEqual(headers.headers.count, 2)
        XCTAssertEqual(
            headers.headers[1].value,
            "Floop the Pig"
        )
    }

    func testParseHeadersTapeDropsEmptyLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Husker knights
            Title: Floop the Pig
            
            Body text
            """
        )
        _ = Headers.parse(&tape)
        let next = tape.consume()
        XCTAssertEqual(next, "B")
    }

    func testParseNoHeaders() throws {
        var tape = Tape("\nBody text\n")
        let headers = Headers.parse(&tape)
        XCTAssertEqual(
            headers.headers.count,
            0
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
            "Content-Type: text/subtext\nContent-Type: text/plain\nTitle: Floop the Pig\n\n",
            "Renders headers, dropping malformed headers"
        )
    }
}
