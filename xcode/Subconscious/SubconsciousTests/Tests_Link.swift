//
//  Tests_Link.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/3/23.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_Link: XCTestCase {
    func testParse() throws {
        let link = try Link("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7/foo/bar")
            .unwrap()
        let slug = try Slug("foo/bar")
            .unwrap()
        XCTAssertEqual(link.did, Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!)
        XCTAssertEqual(link.slug, slug)
    }

    func testRoundtrip() throws {
        let link = try Link("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7/foo/bar")
            .unwrap()
        let link2 = try Link(link.description)
            .unwrap()
        XCTAssertEqual(link, link2)
    }

    func testRejectsInvalidSyntax() throws {
        XCTAssertNil(Link("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"), "Rejects missing slug")
        XCTAssertNil(Link("did:ke%y:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7/foo/bar"), "Rejects invalid method")
        XCTAssertNil(Link("DID:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7/foo/bar"), "Rejects invalid prefix")
        XCTAssertNil(Link("did:key:~/foo/bar"), "Rejects invalid path")
        XCTAssertNil(Link("did:æ:abc123/foo/bar"), "Rejects unicode in did method")
        XCTAssertNil(Link("did:key:ò/foo/bar"), "Rejects unicode in did method function")
    }
}
