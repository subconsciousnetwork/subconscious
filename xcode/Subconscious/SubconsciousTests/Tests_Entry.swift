//
//  Tests_Entry.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/7/22.
//

import XCTest
@testable import Subconscious

final class Tests_Entry: XCTestCase {
    func testMemoEntryMerge() {
        let a = MemoEntry(
            address: MemoAddress(formatting: "example-a", audience: .public)!,
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Example A",
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example A"
            )
        )

        let b = MemoEntry(
            address: MemoAddress(formatting: "example-b", audience: .public)!,
            contents: Memo(
                contentType: ContentType.subtext.rawValue,
                created: Date.now,
                modified: Date.now,
                title: "Example B",
                fileExtension: ContentType.subtext.fileExtension,
                additionalHeaders: [],
                body: "Example B"
            )
        )

        let c = a.merge(b)
        XCTAssertEqual(c.address, a.address, "Keeps subject address")
        XCTAssertEqual(c.contents.title, a.contents.title, "Keeps subject title")
        XCTAssertEqual(
            c.contents.body,
            "Example A\n\nExample B"
        )
    }
}
