//
//  Tests_Editor.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/27/22.
//

import XCTest
@testable import Subconscious

class Tests_Editor: XCTestCase {
    func testSubtextFileInitExtension() throws {
        let editor = Editor(
            entryInfo: EditorEntryInfo(
                slug: Slug("12-networking-truths")!,
                headers: HeaderIndex(
                    [
                        Header(name: "Content-Type", value: "text/subtext"),
                        Header(name: "Title", value: "12 Networking Truths")
                    ]
                )
            )
        )
        let entry = SubtextFile(editor)!
        XCTAssertEqual(
            entry.headers.index.count,
            2,
            "SubtextFile constructor carries over headers"
        )
    }

    /// Tests that standard headers are added to the file.
    func testMendEmptyHeaders() throws {
        var entryInfo = EditorEntryInfo(
            slug: Slug("a-farm-picture")!,
            headers: .empty
        )
        entryInfo.mendHeaders()

        XCTAssertEqual(
            entryInfo.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            entryInfo.headers["Title"],
            "A farm picture",
            "mendHeaders sets Title header"
        )
        XCTAssertNotNil(
            entryInfo.headers["Modified"],
            "mendHeaders sets Modified header"
        )
    }

    /// Tests that standard headers are added to the file.
    func testMendIncompleteHeaders() throws {
        var entryInfo = EditorEntryInfo(
            slug: Slug("a-farm-picture")!,
            headers: HeaderIndex(
                [
                    Header(name: "Title", value: "A Farm Picture"),
                    Header(name: "Author", value: "Walt Whitman"),
                ]
            )
        )
        entryInfo.mendHeaders()

        XCTAssertEqual(
            entryInfo.headers["Content-Type"],
            "text/subtext",
            "mendHeaders sets Content-Type header"
        )
        XCTAssertEqual(
            entryInfo.headers["Title"],
            "A Farm Picture",
            "mendHeaders does not overwrite headers"
        )
        XCTAssertEqual(
            entryInfo.headers["Author"],
            "Walt Whitman",
            "mendHeaders keeps other headers"
        )
    }

    /// Tests that standard headers are added to the file.
    func testMendFixTitle() throws {
        var entryInfo = EditorEntryInfo(
            slug: Slug("a-farm-picture")!,
            headers: HeaderIndex(
                [
                    Header(name: "Content-Type", value: "text/subtext"),
                    Header(name: "Title", value: "Some other title"),
                    Header(name: "Author", value: "Walt Whitman"),
                ]
            )
        )
        entryInfo.mendHeaders()

        XCTAssertEqual(
            entryInfo.headers["Title"],
            "A farm picture",
            "mendHeaders replaces title with linkable title"
        )
        XCTAssertEqual(
            entryInfo.headers["Author"],
            "Walt Whitman",
            "mendHeaders keeps other headers"
        )
    }
}
