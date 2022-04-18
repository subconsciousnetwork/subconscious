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
}
