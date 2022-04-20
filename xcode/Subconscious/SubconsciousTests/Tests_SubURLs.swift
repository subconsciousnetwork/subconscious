//
//  Tests_SubURLs.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/20/22.
//

import XCTest
@testable import Subconscious

class Tests_SubURLs: XCTestCase {
    func testEncodeAsSubEntryURL() throws {
        let link = EntryLink(
            slug: Slug("hidecs")!,
            title: "HIDECS"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        XCTAssertEqual(
            url.absoluteString,
            "sub://entry/hidecs?title=HIDECS"
        )
    }

    func testEncodeAsSubEntryURLNonMatchingTitle() throws {
        let link = EntryLink(
            slug: Slug("title")!,
            title: "Some other title"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        XCTAssertEqual(
            url.absoluteString,
            "sub://entry/title?title=Some%20other%20title"
        )
    }

    func testEncodeDecodeRoundTrip() throws {
        let link = EntryLink(
            slug: Slug("evergreen-notes")!,
            title: "Evergreen Notes"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        guard let link = EntryLink.decodefromSubEntryURL(url) else {
            XCTFail("Expected EntryLink")
            return
        }
        XCTAssertEqual(
            link.title,
            "Evergreen Notes"
        )
        XCTAssertEqual(
            String(link.slug),
            "evergreen-notes"
        )
    }
}
