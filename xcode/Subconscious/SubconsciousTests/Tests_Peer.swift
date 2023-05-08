//
//  Tests_Peer.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/28/23.
//

import XCTest
@testable import Subconscious

final class Tests_Peer: XCTestCase {
    func testPeerIsAbsolute() throws {
        let petname = Petname("ahab")!
        let did = Did("did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK")!
        let rel = Peer.petname(petname)
        let abs = Peer.did(did)
        XCTAssertEqual(rel.isAbsolute, false, "Petname is relative")
        XCTAssertEqual(abs.isAbsolute, true, "Did is absolute")
    }
}
