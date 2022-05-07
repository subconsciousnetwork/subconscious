//
//  Tests_SubtextEnvelope.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/6/22.
//

import XCTest
@testable import Subconscious

class Tests_SubtextEnvelope: XCTestCase {
    func testParse() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Malformed header: Bloop
            Title: Some title
            
            # Body text
            Some text
            """
        )
        let envelope = SubtextEnvelope.parse(&tape)
        XCTAssertEqual(envelope.headers.headers.count, 2)
        XCTAssertEqual(
            envelope.headers.headers[0].normalizedName,
            "content-type"
        )

        XCTAssertEqual(envelope.body.blocks.count, 1)
        XCTAssertEqual(envelope.body.blocks.count, 1)
    }

}
