//
//  Tests_App.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/27/23.
//

import XCTest
@testable import Subconscious

final class Tests_App: XCTestCase {
    func testPersistFirstRunComplete() throws {
        let model = AppModel()
        let up1 = AppModel.update(
            state: model,
            action: .persistFirstRunComplete(true),
            environment: AppEnvironment()
        )
        XCTAssertTrue(up1.state.isFirstRunComplete, "isFirstRunComplete set")
        let up2 = AppModel.update(
            state: model,
            action: .persistFirstRunComplete(false),
            environment: AppEnvironment()
        )
        XCTAssertFalse(up2.state.isFirstRunComplete, "isFirstRunComplete set")
    }
}
