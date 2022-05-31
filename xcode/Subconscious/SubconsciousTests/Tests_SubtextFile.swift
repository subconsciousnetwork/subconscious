//
//  Tests_SubtextFile.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/30/22.
//

import XCTest
@testable import Subconscious

class Tests_SubtextFile: XCTestCase {
    /// Tests that standard headers are added to the file.
    func testMendEmptyHeaders() throws {
        let entry = SubtextFile(
            slug: Slug("a-farm-picture")!,
            content: """
            Through the ample open door of the peaceful country barn,
            A sunlit pasture field with cattle and horses feeding,
            And haze and vista, and the far horizon fading away.
            """
        )
        let mended = entry.mendHeaders()

        XCTAssertEqual(
            mended.envelope.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.envelope.headers["Title"],
            "A farm picture",
            "mendHeaders sets Title header"
        )
        XCTAssertNotNil(
            mended.envelope.headers["Modified"],
            "mendHeaders sets Modified header"
        )
    }

    /// Tests that standard headers are added to the file.
    func testMendIncompleteHeaders() throws {
        let entry = SubtextFile(
            slug: Slug("a-farm-picture")!,
            content: """
            Title: A Farm Picture
            Author: Walt Whitman

            Through the ample open door of the peaceful country barn,
            A sunlit pasture field with cattle and horses feeding,
            And haze and vista, and the far horizon fading away.
            """
        )
        let mended = entry.mendHeaders()

        XCTAssertEqual(
            mended.envelope.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.envelope.headers["Title"],
            "A Farm Picture",
            "mendHeaders does not overwrite headers"
        )
        XCTAssertEqual(
            mended.envelope.headers["Author"],
            "Walt Whitman",
            "mendHeaders keeps other headers"
        )
    }

    /// Tests that standard headers are added to the file.
    func testMendFixTitle() throws {
        let entry = SubtextFile(
            slug: Slug("a-farm-picture")!,
            content: """
            content-type: text/subtext
            Title: Some other title
            Author: Walt Whitman

            Through the ample open door of the peaceful country barn,
            A sunlit pasture field with cattle and horses feeding,
            And haze and vista, and the far horizon fading away.
            """
        )
        let mended = entry.mendHeaders()

        XCTAssertEqual(
            mended.envelope.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.envelope.headers["Title"],
            "A farm picture",
            "mendHeaders replaces title with linkable title"
        )
        XCTAssertEqual(
            mended.envelope.headers["Author"],
            "Walt Whitman",
            "mendHeaders keeps other headers"
        )
    }
}
