//
//  Tests_SubtextFile.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/30/22.
//

import XCTest
@testable import Subconscious

class Tests_SubtextFile: XCTestCase {
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
            entry.content,
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
            entry.title,
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
            entry.excerpt,
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
            c.content,
            """
            Some say the world will end in fire,
            Some say in ice.
            Here come real stars to fill the upper skies,
            And here on earth come emulating flies,
            """
        )
    }

    func testLinkableTitleMissingTitleHeader() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .linkableTitle()

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
        )
    }

    func testLinkableTitleNoTitleHeader() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .linkableTitle()

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
        )
    }

    func testLinkableTitleMismatchTitleHeader() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Title: Floop the Pig
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .linkableTitle()

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
        )
    }

    func testLinkableTitleMatchingTitleHeader() throws {
        let entry = SubtextFile(
            slug: Slug("fire-and-ice")!,
            content: """
            Title: Fire and Ice
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .linkableTitle()

        XCTAssertEqual(
            entry.headers["title"],
            "Fire and Ice"
        )
    }

    func testTitleAndSlugFromSlug() throws {
        let slug = Slug("fire-and-ice")!
        let entry = SubtextFile(
            slug: Slug("some-other-slug")!,
            content: """
            
            Some say the world will end in fire,
            Some say in ice.
            """
        )
        .titleAndSlug(slug)

        XCTAssertEqual(
            entry.slug,
            slug
        )
        XCTAssertEqual(
            entry.headers["title"],
            "Fire and ice"
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
        .titleAndSlug("Fire and Ice")

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
}
