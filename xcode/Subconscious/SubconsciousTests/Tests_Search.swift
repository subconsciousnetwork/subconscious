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

    /// Tests full .hideSearchAndClearQuery sequence, including running fx.
    func testSearchHideAndClearQuery() throws {
        let store = Store(
            state: SearchModel(
                query: "I see red and orange and purple"
            ),
            environment: environment
        )

        store.send(.hideAndClearQuery)

        XCTAssertEqual(
            store.state.query,
            "I see red and orange and purple",
            "Query is not cleared immediately"
        )

        let expectation = XCTestExpectation(
            description: "Query clears query after animation delay"
        )

        let timeout = store.state.clearSearchTimeout + 0.1
        DispatchQueue.main.asyncAfter(
            deadline: .now() + timeout
        ) {
            XCTAssertEqual(
                store.state.query,
                "",
                "Query clears query after animation delay"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    /// Test search submit from keyboard "go" button
    func testSearchSubmitQuery() throws {
        let state = SearchModel()
        let update = SearchModel.update(
            state: state,
            action: .submitQuery("When she smiles there is a subtle glow"),
            environment: environment
        )
        XCTAssertEqual(
            update.state.query,
            "",
            "Query is cleared"
        )
    }

    /// Test search search suggestion activation
    func testActivateSuggestion() throws {
        let state = SearchModel()
        let update = SearchModel.update(
            state: state,
            action: .activateSuggestion(
                Suggestion.memo(
                    address: Slashlink.local(
                        Slug("red-and-orange-and-purple")!
                    )
                )
            ),
            environment: environment
        )
        XCTAssertEqual(
            update.state.query,
            "",
            "Query is cleared"
        )
    }
}
