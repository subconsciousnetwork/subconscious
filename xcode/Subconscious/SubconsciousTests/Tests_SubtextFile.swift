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
        let expectedHeaders = HeaderIndex(
            [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Title", value: "A farm picture"),
            ]
        )

        XCTAssertEqual(
            mended.envelope.headers,
            expectedHeaders,
            "mendHeaders sets expected headers when headers are missing"
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
        let expectedHeaders = HeaderIndex(
            [
                Header(name: "Title", value: "A Farm Picture"),
                Header(name: "Author", value: "Walt Whitman"),
                Header(name: "Content-Type", value: "text/subtext"),
            ]
        )

        XCTAssertEqual(
            mended.envelope.headers,
            expectedHeaders,
            "mendHeaders merges in expected headers"
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
        let expectedHeaders = HeaderIndex(
            [
                Header(name: "Content-Type", value: "text/subtext"),
                Header(name: "Title", value: "A farm picture"),
                Header(name: "Author", value: "Walt Whitman"),
            ]
        )

        XCTAssertEqual(
            mended.envelope.headers,
            expectedHeaders,
            "mendHeaders merges in expected headers"
        )
    }
}
