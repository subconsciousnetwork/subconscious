//
//  Tests_EntryLink.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/19/22.
//

import XCTest
@testable import Subconscious

class Tests_EntryLink: XCTestCase {
    func testSanitizeTitle() throws {
        let title = EntryLink.sanitizeTitle("  RAND\nCorporation  ")
        XCTAssertEqual(
            title,
            "RAND Corporation",
            "Title is santized"
        )
    }

    func testSanitizesTitle() throws {
        let link = EntryLink(
            address: Slashlink.local(Slug(formatting: "rand-corporation")!),
            title: "  RAND\nCorporation    "
        )
        XCTAssertEqual(
            link.title,
            "RAND Corporation",
            "Title is santized"
        )
    }

    func testSanitizesLinkableTitle() throws {
        let link = EntryLink(
            address: Slashlink.local(Slug(formatting: "rand-corporation")!),
            title: "  RAND\nCorporation    "
        )
        XCTAssertEqual(
            link.title,
            "RAND Corporation",
            "Title is santized"
        )
        XCTAssertEqual(
            String(link.linkableTitle),
            "RAND Corporation",
            "Linkable title is sanitized"
        )
        XCTAssertEqual(
            String(link.address.slug),
            "rand-corporation",
            "Title is slugified correctly"
        )
    }

    func testSanitizesNonLinkableTitle() throws {
        let link = EntryLink(
            address: Slashlink.local(Slug(formatting: "something")!),
            title: "  Something else    "
        )
        XCTAssertEqual(
            link.title,
            "Something else",
            "Title is santized"
        )
        XCTAssertEqual(
            String(link.linkableTitle),
            "Something",
            "Linkable title is sanitized"
        )
    }

    /// In cases where the title *is* linkable, we want to make sure
    /// the various sanitization steps don't somehow change the title.
    func testLeavesLinkableTitleFormattingAlone() throws {
        let stringDate = "2022-10-10 10:45:35"

        let link = EntryLink(
            address: Slashlink.local(Slug(formatting: stringDate)!),
            title: stringDate
        )

        XCTAssertEqual(link.linkableTitle, stringDate)
        XCTAssertEqual(link.title, stringDate)
    }

    func testSlugOnlyEntryLinkToLinkableTitle() throws {
        guard
            let address = Slug(formatting: "rand")?.toSlashlink()
        else {
            XCTFail("Expected slug")
            return
        }
        let title = EntryLink(address: address).linkableTitle
        XCTAssertEqual(
            title,
            "Rand",
            "Title is derived by sentence-ifying slug when constructed without title"
        )
    }
}
