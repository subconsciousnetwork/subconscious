//
//  Tests_Memo.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/15/23.
//

import XCTest
@testable import Subconscious

final class Tests_Memo: XCTestCase {
    func testMemoMerge() {
        let a = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Example A",
            fileExtension: ContentType.subtext.fileExtension,
            additionalHeaders: [
                Header(name: "Foo", value: "Foo")
            ],
            body: "Example A"
        )

        let b = Memo(
            contentType: ContentType.subtext.rawValue,
            created: Date.now,
            modified: Date.now,
            title: "Example B",
            fileExtension: ContentType.text.fileExtension,
            additionalHeaders: [
                Header(name: "Bar", value: "Bar"),
                Header(name: "Foo", value: "Bad")
            ],
            body: "Example B"
        )

        let c = a.merge(b)

        // Test that A's headers win
        XCTAssertEqual(c.title, a.title, "Keeps subject title")
        XCTAssertEqual(c.fileExtension, a.fileExtension, "Keeps subject file extension")

        // Test that additional headers are merged
        XCTAssertEqual(c.additionalHeaders.count, 2, "Merges headers")
        let foo = c.additionalHeaders.get(first: "Foo")
        XCTAssertEqual(foo, "Foo", "Merges headers")

        XCTAssertEqual(
            c.body,
            "Example A\n\nExample B",
            "Concatenates bodies"
        )
    }
}
