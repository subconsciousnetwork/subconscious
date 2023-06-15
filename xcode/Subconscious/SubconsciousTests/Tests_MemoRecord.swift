//
//  Tests_MemoRecord.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/15/23.
//

import XCTest
@testable import Subconscious

final class Tests_MemoRecord: XCTestCase {
    func testThrowsWhenInitilizedWithLocalDidWithoutSize() throws {
        XCTAssertThrowsError(
            try MemoRecord(
                did: Did.local,
                petname: nil,
                slug: Slug("foo")!,
                contentType: "text/subtext",
                created: Date.now,
                modified: Date.now,
                title: "Foo",
                fileExtension: "subtext",
                headers: [],
                body: "Foo",
                description: "Foo",
                excerpt: "Foo",
                links: Set()
            ),
            "Throws error because did is local, but no size given"
        )
    }

    func testThrowsWhenInitilizedWithLocalDidWithPetname() throws {
        XCTAssertThrowsError(
            try MemoRecord(
                did: Did.local,
                petname: Petname("eve")!,
                slug: Slug("foo")!,
                contentType: "text/subtext",
                created: Date.now,
                modified: Date.now,
                title: "Foo",
                fileExtension: "subtext",
                headers: [],
                body: "Foo",
                description: "Foo",
                excerpt: "Foo",
                links: Set(),
                size: 10
            ),
            "Throws error because did is local, but petname is given"
        )
    }
}
