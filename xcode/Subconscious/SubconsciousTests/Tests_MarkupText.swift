//
//  Tests_MarkupText.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/19/22.
//

import XCTest
import ObservableStore
@testable import Subconscious

final class Tests_MarkupText: XCTestCase {
    func testRequestFocus() {
        let store = Store(
            state: SubtextTextModel(),
            environment: ()
        )

        store.send(.requestFocus(true))

        let expectation = XCTestExpectation(
            description: "focus set to true"
        )
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            XCTAssertEqual(
                store.state.focusRequest,
                true,
                "Focus request was set"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)
    }
}
