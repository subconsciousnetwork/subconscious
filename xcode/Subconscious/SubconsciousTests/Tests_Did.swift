//
//  Tests_Did.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 2023-03-01
//

import XCTest
@testable import Subconscious

class Tests_Did: XCTestCase {
    func testValidDid() throws {
        let did = Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")
        XCTAssertNotNil(did)
    }
    
    func testValidDid2() throws {
        let did = Did("did:web:example.com")
        XCTAssertNotNil(did)
    }

    func testEmptyDid() throws {
        let did = Did("")
        XCTAssertNil(did)
    }
    
    func testCutOffDid() throws {
        let did = Did("did:x")
        XCTAssertNil(did)
    }
    
    func testCutOffDid2() throws {
        let did = Did("did:key:")
        XCTAssertNil(did)
    }
    
    func testPlausibleDid() throws {
        let did = Did("did:key:helloworld")
        XCTAssertNotNil(did)
    }
}
