//
//  Tests_SubtextFile.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/30/22.
//

import XCTest
@testable import Subconscious

class Tests_SubtextFile: XCTestCase {
    func testInitBlessedHeaders() throws {
        let then = Date(timeIntervalSince1970: 0)
        let thenISO = then.ISO8601Format()
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            title: "Fire and Ice",
            modified: then,
            created: then,
            body: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            entry.headers["Title"],
            "Fire and Ice"
        )
        XCTAssertEqual(
            entry.headers["Modified"],
            thenISO
        )
        XCTAssertEqual(
            entry.headers["Created"],
            thenISO
        )
    }

    func testInitBlessedHeadersNonlinkableTitle() throws {
        let now = Date.now
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            title: "Nonlinkable title",
            modified: now,
            created: now,
            body: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            entry.headers["Title"],
            "Fire and ice"
        )
    }

    func testContentParsing() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            entry.body,
            "Some say the world will end in fire,\nSome say in ice.",
            "Entry description produces correctly formatted document"
        )
    }

    func testDescription() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            String(describing: entry),
            "Title: Fire and Ice\nAuthor: Robert Frost\n\nSome say the world will end in fire,\nSome say in ice.",
            "Entry description produces correctly formatted document"
        )
    }

    func testTitle() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            entry.title(),
            "Fire and Ice"
        )
    }

    func testExcerpt() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        XCTAssertEqual(
            entry.excerpt(),
            "Some say the world will end in fire,",
            "Excerpt pulls first line of body"
        )
    }

    func testSize() throws {
        let body = """
        title: Fire and Ice
        author: Robert Frost

        Some say the world will end in fire,
        Some say in ice.
        """
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: body
        )
        XCTAssertEqual(
            entry.size,
            body.lengthOfBytes(using: .utf8),
            "Size matches full document size, including headers"
        )
    }

    func testMerge() throws {
        let a = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            title: Fire and Ice
            author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )

        let b = SubtextFile(
            slug: Slug("fireflies-in-the-garden")!,
            content: """
            title: Fireflies in the Garden
            author: Robert Frost
            year: 1928

            Here come real stars to fill the upper skies,
            And here on earth come emulating flies,
            """
        )

        let c = a.merge(b)

        XCTAssertEqual(
            c.headers["Title"],
            "Fire and Ice"
        )
        XCTAssertEqual(
            c.headers["author"],
            "Robert Frost"
        )
        XCTAssertEqual(
            c.headers["year"],
            "1928"
        )
        XCTAssertEqual(
            c.body,
            """
            Some say the world will end in fire,
            Some say in ice.
            Here come real stars to fill the upper skies,
            And here on earth come emulating flies,
            """
        )
    }

    func testTitleAndSlugNoTitleHeader() throws {
        let slug = Slug("fire-and-ice")!
        let entry = SubtextFile(
            slug: slug,
            content: """
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .slugAndTitle(slug)

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
        )
    }

    func testLinkableTitleMismatchTitleHeader() throws {
        let slug = Slug("fire-and-ice")!
        let entry = SubtextFile(
            slug: slug,
            content: """
            Title: Floop the Pig
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .slugAndTitle(slug)

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
        )
    }

    func testSlugAndTitleMatchingProposedTitle() throws {
        let slug = Slug("fire-and-ice")!
        let entry = SubtextFile(
            slug: slug,
            content: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .slugAndTitle(EntryLink(slug: slug, title: "Fire and Ice"))

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and Ice"
        )
    }

    func testSlugAndTitleMismatchProposedTitle() throws {
        let slug = Slug("fire-and-ice")!
        let entry = SubtextFile(
            slug: slug,
            content: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .slugAndTitle(EntryLink(slug: slug, title: "Not a linkable title"))

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice",
            "Falls back on deriving title from slug"
        )
    }

    func testTitleAndSlugFromTitle() throws {
        let entry = SubtextFile(
            slug: Slug("some-other-slug")!,
            content: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .slugAndTitle("Fire and Ice")

        guard let entry = entry else {
            XCTFail("Title could not be slugified")
            return
        }
        XCTAssertEqual(
            entry.slug,
            Slug("fire-and-ice")!
        )
        XCTAssertEqual(
            entry.headers["title"],
            "Fire and Ice"
        )
    }

    func testMendingMissingHeaders() throws {
        let now = Date.now
        let nowISO = now.ISO8601Format()
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .mendingHeaders(modified: now)

        XCTAssertEqual(
            entry.headers["Title"],
            "Fire and ice",
            "Default title derived from slug when missing"
        )
        XCTAssertEqual(
            entry.headers["Modified"],
            nowISO,
            "Defaults modified to date provided"
        )
        XCTAssertEqual(
            entry.headers["Created"],
            nowISO,
            "Defaults created to date provided"
        )
    }

    func testMendingSomeHeaders() throws {
        let now = Date.now
        let nowISO = now.ISO8601Format()
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Title: Non-linkable title
            Author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .mendingHeaders(modified: now)

        XCTAssertEqual(
            entry.headers["Title"],
            "Non-linkable title",
            "Does not overwrite existing title"
        )
        XCTAssertEqual(
            entry.headers["Author"],
            "Robert Frost",
            "Leaves other headers alone"
        )
        XCTAssertEqual(
            entry.headers["Modified"],
            nowISO,
            "Defaults created to date provided"
        )
    }

    func testModified() throws {
        let now = Date.now
        let nowISO = now.ISO8601Format()
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Title: Non-linkable title
            Author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .modified(now)
        XCTAssertEqual(
            entry.headers["Modified"],
            nowISO,
            "Sets modified to date provided"
        )
    }

    func testCreated() throws {
        let now = Date.now
        let nowISO = now.ISO8601Format()
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Title: Non-linkable title
            Author: Robert Frost

            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .created(now)
        XCTAssertEqual(
            entry.headers["Created"],
            nowISO,
            "Sets created to date provided"
        )
    }
}
