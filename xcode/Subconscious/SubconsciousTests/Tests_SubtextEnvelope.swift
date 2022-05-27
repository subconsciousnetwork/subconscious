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
        let envelope = SubtextEnvelope.parse(
            markup: """
            Content-Type: text/subtext
            Malformed header: Bloop
            Title: Some title
            
            # Body text
            Some text
            """
        )
        XCTAssertEqual(envelope.headers.headers.count, 2)
        XCTAssertEqual(
            envelope.headers.headers[0].normalizedName,
            "Content-Type"
        )

        XCTAssertEqual(envelope.body.blocks.count, 2)
        guard case let .heading(heading) = envelope.body.blocks[0] else {
            XCTFail("Expected heading")
            return
        }
        XCTAssertEqual(heading, "# Body text")
    }

    func testRenderRoundtrip() throws {
        let envelope = SubtextEnvelope.parse(
            markup: """
            Content-Type: text/subtext
            Malformed header: Bloop
            Title: Double, double toil and trouble
            
            (from Macbeth)
            Double, double toil and trouble;
            Fire burn and caldron bubble.
            """
        )
        XCTAssertEqual(
            String(describing: envelope),
            """
            Content-Type: text/subtext
            Title: Double, double toil and trouble
            
            (from Macbeth)
            Double, double toil and trouble;
            Fire burn and caldron bubble.
            """
        )
    }

    func testRenderRoundtripNormalization() throws {
        let envelope = SubtextEnvelope.parse(
            markup: """
            CONTENT-TYPE: text/subtext
            title: Double, double toil and trouble
            
            (from Macbeth)
            Double, double toil and trouble;
            Fire burn and caldron bubble.
            """
        )
        XCTAssertEqual(
            String(describing: envelope),
            """
            Content-Type: text/subtext
            Title: Double, double toil and trouble
            
            (from Macbeth)
            Double, double toil and trouble;
            Fire burn and caldron bubble.
            """
        )
    }
}
