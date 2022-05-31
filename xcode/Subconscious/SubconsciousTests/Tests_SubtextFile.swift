//
//  Tests_SubtextFile.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/30/22.
//

import XCTest
@testable import Subconscious

class Tests_SubtextFile: XCTestCase {
    func testDescription() throws {
        let entry = SubtextFile(
            slug: Slug("a-farm-picture")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            String(describing: entry),
            "Title: Fire and Ice\nAuthor: Robert Frost\n\nSome say the world will end in fire,\nSome say in ice.",
            "Entry description produces correctly formatted document"
        )
    }

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
            mended.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.headers["Title"],
            "A farm picture",
            "mendHeaders sets Title header"
        )
        XCTAssertNotNil(
            mended.headers["Modified"],
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
            mended.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.headers["Title"],
            "A Farm Picture",
            "mendHeaders does not overwrite headers"
        )
        XCTAssertEqual(
            mended.headers["Author"],
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
            mended.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            mended.headers["Title"],
            "A farm picture",
            "mendHeaders replaces title with linkable title"
        )
        XCTAssertEqual(
            mended.headers["Author"],
            "Walt Whitman",
            "mendHeaders keeps other headers"
        )
    }
}
