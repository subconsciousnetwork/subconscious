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
        XCTAssertEqual(envelope.headers.index.count, 2)
        XCTAssertEqual(
            String(describing: envelope.headers.index.keys[0]),
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

    func testBodyTextNoHeaders() throws {
        let envelope = SubtextEnvelope.parse(
            markup: """
            Over hill, over dale,
            Thorough bush, thorough brier,
            Over park, over pale,
            """
        )
        XCTAssertEqual(
            envelope.body.base,
            """
            Over hill, over dale,
            Thorough bush, thorough brier,
            Over park, over pale,
            """
        )
    }

    func testBodyTextEmptyHeaders() throws {
        let envelope = SubtextEnvelope.parse(
            markup: """

            Thorough flood, thorough fire,
            I do wander everywhere,
            Swifter than the moon's sphere;
            """
        )
        XCTAssertEqual(
            envelope.body.base,
            """
            Thorough flood, thorough fire,
            I do wander everywhere,
            Swifter than the moon's sphere;
            """
        )
    }

    func testBodyTextHeaders() throws {
        let envelope = SubtextEnvelope.parse(
            markup: """
            Content-Type: text/subtext
            Title: A wood near Athens

            Thorough flood, thorough fire,
            I do wander everywhere,
            Swifter than the moon's sphere;
            """
        )
        XCTAssertEqual(
            envelope.body.base,
            """
            Thorough flood, thorough fire,
            I do wander everywhere,
            Swifter than the moon's sphere;
            """
        )
    }

    func testAppend() throws {
        let a = SubtextEnvelope.parse(
            markup: "content-type: text/subtext\ntitle: Double, double toil and trouble\n\nDouble, double toil and trouble;\nFire burn and caldron bubble."
        )
        let b = SubtextEnvelope.parse(
            markup: "CONTENT-TYPE: text/subtext\ntitle: A desert place\n\nWhen shall we three meet again\nIn thunder, lightning, or in rain?"
        )
        let c = a.append(b)

        XCTAssertEqual(
            String(describing: c),
            """
            Content-Type: text/subtext
            Title: Double, double toil and trouble
            
            Double, double toil and trouble;
            Fire burn and caldron bubble.
            When shall we three meet again
            In thunder, lightning, or in rain?
            """
        )
    }
}
