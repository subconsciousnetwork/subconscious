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

    func testSlugOnlyEntryLinkToLinkableSentence() throws {
        guard let slug = Slug("rand") else {
            XCTFail("Expected slug")
            return
        }
        let title = EntryLink(slug: slug).toLinkableSentence()
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
        let title = link.toLinkableSentence()
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
        let title = link.toLinkableSentence()
        XCTAssertEqual(
            title,
            "Rand",
            "Sentence-ified slug is used for wikilink text when slugified title does not match slug"
        )
    }
}
