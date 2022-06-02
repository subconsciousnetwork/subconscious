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
}
