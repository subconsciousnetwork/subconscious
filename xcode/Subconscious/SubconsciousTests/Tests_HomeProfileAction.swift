//
//  Tests_HomeProfileAction.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/23/23.
//

import XCTest
@testable import Subconscious

final class Tests_HomeProfileAction: XCTestCase {
    typealias Action = HomeProfileAction
    
    func testFromSucceedIndexOurSphere() throws {
        let action = Action.from(
            .succeedIndexOurSphere(
                OurSphereRecord(
                    identity: Did("did:key:abc123")!,
                    since: "bafyfakefakefake"
                )
            )
        )
        XCTAssertEqual(action, .ready)
    }
    
    func testFromSucceedDeleteMemo() throws {
        let action = Action.from(
            .succeedDeleteMemo(Slashlink("/foo")!)
        )
        XCTAssertEqual(action, .succeedDeleteMemo(Slashlink("/foo")!))
    }
    
    func testFromFailDeleteMemo() throws {
        let action = Action.from(
            .failDeleteMemo("")
        )
        XCTAssertEqual(action, .failDeleteMemo(""))
    }
    
    func testFromRequestFeedRoot() throws {
        let action = Action.from(
            .requestProfileRoot
        )
        XCTAssertEqual(action, .requestProfileRoot)
    }
}
