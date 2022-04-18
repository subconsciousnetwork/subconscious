//
//  Tests_HeaderParser.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/18/22.
//

import XCTest
@testable import Subconscious

class Tests_HeaderParser: XCTestCase {
    func testStopsParsingAtFirstEmptyLine() throws {
        let markup = """
        Content-Type: text/subtext
        Title: Floop the Pig
        Date: 2022-03-18

        Body content
        """
        let headers = HeaderParser(markup)

        XCTAssertEqual(
            headers.headers.count,
            3,
            "Stops parsing headers at first empty line"
        )
    }

    func testStopsBeforeHeaderlikeContentInBody() throws {
        let markup = """
        Content-Type: text/subtext
        Title: Floop the Pig
        
        Body: content
        """
        let headers = HeaderParser(markup)
        XCTAssertEqual(
            headers.headers.count,
            2,
            "Stops parsing after first blank line"
        )
    }

    func testHeaders() throws {
        let markup = """
        Content-Type: text/subtext
        Title: Floop the Pig
        
        Body content
        """
        let headers = HeaderParser(markup)
        XCTAssertEqual(
            String(headers.headers[0].name),
            "Content-Type"
        )
    }

    func testMoreHeaders() throws {
        let markup = """
        Content-Type: text/subtext
        Title: Floop the Pig
        Accept: */*
        Cache-Control: no-cache
        Content-Length: 438
        Vary: Accept-Encoding,User-Agent
        Connection: close
        Date: Thu, 08 Sep 2011 08:57:00 GMT
        Server: Apache
        
        Body content
        """
        let headers = HeaderParser(markup)
        XCTAssertEqual(
            String(headers.headers[0].name),
            "Content-Type"
        )
    }

    func testValueOmitsNewline() throws {
        let markup = """
        Content-Type: text/subtext
        Title : Floop the Pig
        
        Body content
        """
        let headers = HeaderParser(markup)

        XCTAssertEqual(
            String(headers.headers[0].value),
            "text/subtext",
            "Value omits leading spaces and trailing newline"
        )
    }

    func testSniffsFirstLine() throws {
        let markup = """
        Not a header
        Content-Type: text/subtext
        Title : Floop the Pig

        Body content
        """
        let headers = HeaderParser(markup)
        XCTAssertEqual(
            headers.headers.count,
            0,
            "Sniffs first line to see if it should expect headers"
        )
    }

    func testRejectsKeysWithSpaces() throws {
        let markup = """
        Content-Type: text/subtext
        Title : Floop the Pig
        
        Body content
        """
        let headers = HeaderParser(markup)

        XCTAssertEqual(
            headers.headers.count,
            1,
            "Rejects headers that have spaces in keys"
        )
    }

    func testRejectsKeysWithSpaces2() throws {
        let markup = """
        Content-Type: text/subtext
        Title: Floop the Pig
        Accept: */*
        Cache-Control: no-cache
        Key with space: some text
        Content-Length: 438
        Vary: Accept-Encoding,User-Agent
        Connection: close
        Date: Thu, 08 Sep 2011 08:57:00 GMT
        Server: Apache
        
        Body content
        """
        let headers = HeaderParser(markup)

        XCTAssertEqual(
            headers.headers.count,
            9,
            "Rejects headers that have spaces in keys"
        )

        XCTAssertEqual(
            headers.headers[4].name,
            "Content-Length",
            "Rejects headers that have spaces in keys"
        )
    }

    func testRejectsNonAsciiKeys() throws {
        let markup = """
        Title: Floop the Pig
        Non-Ascii-Header-Key-😈: mwhahaha

        Body content
        """
        let headers = HeaderParser(markup)

        XCTAssertEqual(
            headers.headers.count,
            1,
            "Rejects headers that have non-ascii characters in keys"
        )
    }
}
