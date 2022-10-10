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

    func testSanitizeTitle() throws {
        let title = EntryLink.sanitizeTitle("  RAND\nCorporation  ")
        XCTAssertEqual(
            title,
            "RAND Corporation",
            "Title is santized"
        )
    }

    func testSanitizesTitle() throws {
        guard let link = EntryLink(title: "  RAND\nCorporation    ") else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        XCTAssertEqual(
            link.title,
            "RAND Corporation",
            "Title is santized"
        )
        XCTAssertEqual(
            String(link.slug),
            "rand-corporation",
            "Title is slugified correctly"
        )
    }

    func testSanitizesLinkableTitle() throws {
        let text = "  RAND\nCorporation    "
        let link = EntryLink(
            slug: Slug(formatting: text)!,
            title: text
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
            String(link.slug),
            "rand-corporation",
            "Title is slugified correctly"
        )
    }

    func testSanitizesNonLinkableTitle() throws {
        let link = EntryLink(
            slug: Slug("something")!,
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
        guard let slug = Slug(formatting: stringDate) else {
            XCTFail("Expected slug")
            return
        }
        let link = EntryLink(
            slug: slug,
            title: stringDate
        )
        XCTAssertEqual(link.linkableTitle, stringDate)
        XCTAssertEqual(link.title, stringDate)
    }

    func testSlugOnlyEntryLinkToLinkableSentence() throws {
        guard let slug = Slug("rand") else {
            XCTFail("Expected slug")
            return
        }
        let title = EntryLink(slug: slug).linkableTitle
        XCTAssertEqual(
            title,
            "Rand",
            "Title is derived by sentence-ifying slug when constructed without title"
        )
    }

    func testWikilinkMarkupWithTitleMatchingSlug() throws {
        guard let link = EntryLink(title: "RAND") else {
            XCTFail("Expected title to parse to slug successfully")
            return
        }
        let title = link.linkableTitle
        XCTAssertEqual(
            title,
            "RAND",
            "Title is used for wikilink text when slugified title matches slug"
        )
    }

    func testWikilinkMarkupWithTitleNotMatchingSlug() throws {
        guard let slug = Slug("rand") else {
            XCTFail("Expected slug")
            return
        }
        let link = EntryLink(
            slug: slug,
            title: "RAND Corporation"
        )
        let title = link.linkableTitle
        XCTAssertEqual(
            title,
            "Rand",
            "Sentence-ified slug is used for wikilink text when slugified title does not match slug"
        )
    }
}
