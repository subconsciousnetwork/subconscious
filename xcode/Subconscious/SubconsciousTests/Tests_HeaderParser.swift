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
        guard let headers = HeaderParser(markup) else {
            XCTFail("Failed to parse headers")
            return
        }

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
        guard let headers = HeaderParser(markup) else {
            XCTFail("Failed to parse headers")
            return
        }

        XCTAssertEqual(
            String(headers.headers[0].name),
            "Content-Type"
        )
    }
}
