//
//  Tests_HomeProfile+AppAction.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/23/23.
//

import XCTest

@testable import Subconscious

final class Tests_HomeProfile_AppAction: XCTestCase {
    func testFromRequestDeleteMemo() throws {
        let action = AppAction.from(
            HomeProfileAction.requestDeleteEntry(
                Slashlink("/bob")!
            )
        )
        XCTAssertEqual(action, .deleteEntry(Slashlink("/bob")!))
    }
}
