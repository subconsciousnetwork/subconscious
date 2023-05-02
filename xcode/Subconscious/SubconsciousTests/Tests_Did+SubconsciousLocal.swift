//
//  Tests_Did+SubconsciousLocal.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/2/23.
//

import XCTest
@testable import Subconscious

final class Tests_Did_SubconsciousLocal: XCTestCase {
    func testIsLocal() throws {
        let a = Slashlink(
            peer: .did(Did.local),
            slug: Slug("foo")!
        )
        XCTAssertTrue(a.isLocal)
        
        let b = Slashlink(
            peer: .petname(Petname("alice")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(b.isLocal)

        let c = Slashlink(
            peer: .did(Did("did:key:abc123")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(c.isLocal)
    }

    func testToAudience() throws {
        let a = Slashlink(
            peer: .did(Did.local),
            slug: Slug("foo")!
        )
        XCTAssertEqual(a.toAudience(), Audience.local)
        
        let b = Slashlink(
            peer: .petname(Petname("alice")!),
            slug: Slug("foo")!
        )
        XCTAssertEqual(b.toAudience(), Audience.public)

        let c = Slashlink(
            peer: .did(Did("did:key:abc123")!),
            slug: Slug("foo")!
        )
        XCTAssertEqual(c.toAudience(), Audience.public)
    }
    
    func testIsOurs() throws {
        let a = Slashlink(
            peer: .did(Did.local),
            slug: Slug("foo")!
        )
        XCTAssertTrue(a.isOurs)
        
        let b = Slashlink(
            slug: Slug("foo")!
        )
        XCTAssertTrue(b.isOurs)
        
        let c = Slashlink(
            peer: .petname(Petname("alice")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(c.isOurs)

        let d = Slashlink(
            peer: .did(Did("did:key:abc123")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(d.isOurs)
    }
}
