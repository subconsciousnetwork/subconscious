//
//  Tests_EntryLink.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/19/22.
//

import XCTest
@testable import Subconscious

class Tests_EntryLink: XCTestCase {
    func testTitle() throws {
        guard let link = EntryLink(title: "RAND Corporation") else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        XCTAssertEqual(
            link.title,
            "RAND Corporation",
            "Title matches title given"
        )
        XCTAssertEqual(
            String(link.slug),
            "rand-corporation",
            "Title is slugified correctly"
        )
    }

    func testDeepTitle() throws {
        guard let link = EntryLink(title: "A deep title/With children") else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        XCTAssertEqual(
            String(link.slug),
            "a-deep-title/with-children",
            "Title with slashes is converted to deep slug"
        )
    }
}
