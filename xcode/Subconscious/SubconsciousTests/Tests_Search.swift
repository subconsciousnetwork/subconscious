//
//  Tests_Search.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/9/22.
//

import XCTest
import ObservableStore
@testable import Subconscious

class Tests_Search: XCTestCase {
    let environment = AppEnvironment()

    func testSetSearch() throws {
        let state = SearchModel()
        let update = SearchModel.update(
            state: state,
            action: .setQuery("Mother Nature seems to love us so"),
            environment: environment
        )

        XCTAssertEqual(
            update.state.query,
            "Mother Nature seems to love us so",
            "Set search returns same string"
        )
    }

    func testSearchPresented() throws {
        let state = SearchModel()
        let update = SearchModel.update(
            state: state,
            action: .setPresented(false),
            environment: environment
        )

        XCTAssertEqual(
            update.state.isPresented,
            false,
            "isPresented is false"
        )

        XCTAssertEqual(
            update.state.query,
            "",
            "Search Text Returns Blank"
        )
    }
}
