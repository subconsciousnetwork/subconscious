//
//  Tests_StringUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/19/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

class Tests_StringUtilities: XCTestCase {
    func testTrimming0() throws {
        let fixture = "    wow     "
        let substring = fixture[...]
        XCTAssertEqual(
            substring.trimming(" "),
            "wow"
        )
    }

    func testTrimming1() throws {
        let fixture = "    wow wow wow"
        let substring = fixture[...]
        XCTAssertEqual(
            substring.trimming(" "),
            "wow wow wow"
        )
    }

    func testTrimming2() throws {
        let fixture = "wow wow wow     "
        let substring = fixture[...]
        XCTAssertEqual(
            substring.trimming(" "),
            "wow wow wow"
        )
    }

    func testDeletingPathExtension() throws {
        let fixture = "foo/bar/baz.bing.txt"
        XCTAssertEqual(
            fixture.deletingPathExtension(),
            "foo/bar/baz",
            "Removes everything after first ."
        )
    }

    func testDeletingPathExtensionWeirdExtension() throws {
        let fixture = "foo/bar/baz.bing/foo.txt"
        // TODO: This is expected behavior, but perhaps we should consider
        // doing something more intelligent in future.
        XCTAssertEqual(
            fixture.deletingPathExtension(),
            "foo/bar/baz",
            "Removes everything after first ., even if this includes pathlike components"
        )
    }

    func testDeletingPathExtensionNoExtension() throws {
        let fixture = "foo"
        XCTAssertEqual(
            fixture.deletingPathExtension(),
            "foo",
            "Does not modify path without dot"
        )
    }

    func testcapitalizingFirst() throws {
        let fixture = "the quick brown fox jumped over the lazy dog"
        XCTAssertEqual(
            fixture.capitalizingFirst(),
            "The quick brown fox jumped over the lazy dog"
        )
    }
}
