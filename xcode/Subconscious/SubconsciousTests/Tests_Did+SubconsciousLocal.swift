//
//  Tests_Did+SubconsciousLocal.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/2/23.
//

import XCTest
@testable import Subconscious

final class Tests_Did_SubconsciousLocal: XCTestCase {
    func testDidIsLocal() throws {
        XCTAssertTrue(Did.local.isLocal)
    }
    
    func testSlashlinkIsLocal() throws {
        let a = Slashlink(
            peer: .did(Did.local),
            slug: Slug("foo")!
        )
        XCTAssertTrue(a.isLocal)
        
        let b = Slashlink(
            peer: .did(Did.local),
            slug: Slug.profile
        )
        XCTAssertTrue(b.isLocal)

        let c = Slashlink(
            peer: .petname(Petname("alice")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(c.isLocal)
        
        let d = Slashlink(
            peer: .did(Did("did:key:abc123")!),
            slug: Slug("foo")!
        )
        XCTAssertFalse(d.isLocal)
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
    
    func testSlugToLocalSlashlink() throws {
        let foo = Slug("foo")!
        let slashlink = foo.toLocalSlashlink()
        XCTAssertEqual(slashlink.peer, Peer.did(Did.local))
    }
    
    func testSlugToLocalLink() throws {
        let foo = Slug("foo")!
        let link = foo.toLocalLink()
        XCTAssertEqual(link?.did, Did.local)
    }

    func testToSlashlinkAudience() throws {
        let foo = Slug("foo")!
        let localSlashlink = foo.toSlashlink(audience: .local)
        XCTAssertEqual(localSlashlink.peer, Peer.did(Did.local))
        
        let publicSlashlink = foo.toSlashlink(audience: .public)
        XCTAssertEqual(publicSlashlink.peer, nil)
    }
    
    func testWithAudiencePublic() throws {
        let publicSlashlink = Slashlink("/foo")!
        let localSlashlink = publicSlashlink.withAudience(.local)
        XCTAssertEqual(localSlashlink.peer, Peer.did(Did.local))
    }
    
    func testWithAudienceLocal() throws {
        let localSlashlink = Slashlink(
            peer: Peer.did(Did.local),
            slug: Slug("foo")!
        )
        let publicSlashlink = localSlashlink.withAudience(.public)
        XCTAssertNil(publicSlashlink.peer)
    }
    
    func testWithAudienceDropsPetname() throws {
        let aliceSlashlink = Slashlink("@alice/foo")!
        let publicSlashlink = aliceSlashlink.withAudience(.public)
        XCTAssertNil(publicSlashlink.peer)
    }
}
