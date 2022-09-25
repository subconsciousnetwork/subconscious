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
    }
    
    func testSearchHideAndClearQuery() throws {
        let state = SearchModel(
            query: "I see red and orange and purple"
        )
        let update = SearchModel.update(
            state: state,
            action: .hideAndClearQuery,
            environment: environment
        )
        XCTAssertEqual(
            update.state.isPresented,
            false,
            "Search is hidden"
        )
        XCTAssertEqual(
            update.state.query,
            "",
            "Query is cleared"
        )
        XCTAssertNotNil(
            update.transaction,
            "Transaction is not nil (for hide animation)"
        )
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
            update.state.isPresented,
            false,
            "Search is hidden"
        )
        XCTAssertEqual(
            update.state.query,
            "",
            "Query is cleared"
        )
        XCTAssertNotNil(
            update.transaction,
            "Transaction is not nil (hide animation)"
        )
    }

    /// Test search search suggestion activation
    func testActivateSuggestion() throws {
        let state = SearchModel()
        let update = SearchModel.update(
            state: state,
            action: .activateSuggestion(
                Suggestion.entry(
                    EntryLink(title: "Red and orange and purple")!
                )
            ),
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
            "Query is cleared"
        )
        XCTAssertNotNil(
            update.transaction,
            "Transaction is not nil (hide animation)"
        )
    }
}
