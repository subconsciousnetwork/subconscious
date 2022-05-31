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
            slug: Slug("a-farm-picture")!,
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
            slug: Slug("a-farm-picture")!,
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
            slug: Slug("a-farm-picture")!,
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
            slug: Slug("a-farm-picture")!,
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
}
