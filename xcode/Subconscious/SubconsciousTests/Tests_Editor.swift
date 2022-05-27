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
            slug: Slug("12-networking-truths")!,
            headers: Headers(
                headers: [
                    Header(name: "Content-Type", value: "text/subtext"),
                    Header(name: "Title", value: "12 Networking Truths")
                ]
            )
        )
        let entry = SubtextFile(editor)!
        XCTAssertEqual(
            entry.envelope.headers.headers.count,
            2,
            "SubtextFile constructor carries over headers"
        )
    }
}
