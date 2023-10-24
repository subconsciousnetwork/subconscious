//
//  Tests_FeedAction.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/23/23.
//

import XCTest
@testable import Subconscious

final class Tests_FeedAction: XCTestCase {
    func testFromSucceedIndexOurSphere() throws {
        let action = FeedAction.from(
            .succeedIndexOurSphere(
                OurSphereRecord(
                    identity: Did("did:key:abc123")!,
                    since: "bafyfakefakefake"
                )
            )
        )
        XCTAssertEqual(action, .refreshAll)
    }
    
    func testFromSucceedRecoverOurSphere() throws {
        let action = FeedAction.from(
            .succeedRecoverOurSphere
        )
        XCTAssertEqual(action, .refreshAll)
    }
    
    func testFromSucceedDeleteMemo() throws {
        let action = FeedAction.from(
            .succeedDeleteMemo(Slashlink("/foo")!)
        )
        XCTAssertEqual(action, .succeedDeleteMemo(Slashlink("/foo")!))
    }
    
    func testFromFailDeleteMemo() throws {
        let action = FeedAction.from(
            .failDeleteMemo("")
        )
        XCTAssertEqual(action, .failDeleteMemo(""))
    }
    
    func testFromRequestFeedRoot() throws {
        let action = FeedAction.from(
            .requestFeedRoot
        )
        XCTAssertEqual(action, .requestFeedRoot)
    }
}
