//
//  Tests_SubURL.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/20/22.
//

import XCTest
@testable import Subconscious

class Tests_SubURL: XCTestCase {
    func testEncodeAsSubEntryURL() throws {
        let link = UnqualifiedLink(
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
        let link = UnqualifiedLink(
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

    func testEncodeDecodeRoundTrip0() throws {
        let link = UnqualifiedLink(
            slug: Slug("evergreen-notes")!,
            title: "Evergreen Notes"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        guard let link = UnqualifiedLink.decodefromSubEntryURL(url) else {
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

    func testEncodeDecodeRoundTrip1() throws {
        let link = UnqualifiedLink(
            slug: Slug(formatting: "Baháʼí")!,
            title: "Baháʼí"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        guard let link = UnqualifiedLink.decodefromSubEntryURL(url) else {
            XCTFail("Expected EntryLink")
            return
        }
        XCTAssertEqual(
            link.title,
            "Baháʼí"
        )
        XCTAssertEqual(
            String(link.slug),
            "baháʼí"
        )
    }

    func testEncodeDecodeRoundTrip2() throws {
        let link = UnqualifiedLink(
            slug: Slug(formatting: "Fédération Aéronautique Internationale")!,
            title: "Fédération Aéronautique Internationale"
        )
        guard let url = link.encodeAsSubEntryURL() else {
            XCTFail("Expected URL")
            return
        }
        guard let link = UnqualifiedLink.decodefromSubEntryURL(url) else {
            XCTFail("Expected EntryLink")
            return
        }
        XCTAssertEqual(
            link.title,
            "Fédération Aéronautique Internationale"
        )
        XCTAssertEqual(
            String(link.slug),
            "fédération-aéronautique-internationale"
        )
    }
}
