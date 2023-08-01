//
//  Tests_Audience.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/10/23.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

final class Tests_Audience: XCTestCase {
    func testAudienceUserDescription() throws {
        let local = Audience.local
        XCTAssertEqual(local.userDescription, "Draft")
        
        let `public` = Audience.public
        XCTAssertEqual(`public`.userDescription, "Public")
    }
    
    func testAudienceLosslessStringConvertible() throws {
        let local = Audience("local")
        XCTAssertEqual(local, Audience.local)
        
        let `public` = Audience("public")
        XCTAssertEqual(`public`, Audience.public)
    }
}
