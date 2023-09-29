//
//  Tests_RecoveryMode.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/29/23.
//

import XCTest
@testable import Subconscious

final class Tests_RecoveryMode: XCTestCase {
    func testPressRecoverButtonAlreadySucceeded() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .succeeded
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            state,
            update.state,
            "Pressing recover button when recovery has already succeeded is a no-op"
        )
    }
}
