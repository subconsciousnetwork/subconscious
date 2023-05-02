//
//  Tests_DatabaseService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/7/22.
//

import XCTest
@testable import Subconscious

class Tests_DatabaseService: XCTestCase {
    func testCollateRenameSuggestionsMove() throws {
        let current = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let query = Slashlink("/the-whale-the-whale")!
        let results = [
            current,
            Slashlink("/oh-all-ye-sweet-powers-of-air-now-hug-me-close")!,
            Slashlink("/stubbs-own-unwinking-eye")!,
            Slashlink("/pole-pointed-prow")!,
        ]
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: results
        )
        guard case let .move(from, to) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be move, but was \(suggestion)"
            )
            return
        }
        XCTAssertEqual(
            from,
            current
        )
        XCTAssertEqual(
            to,
            query
        )
    }

    func testCollateRenameSuggestionsMerge() throws {
        let current = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let query = Slashlink("/the-whale-the-whale")!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                Slashlink("/ye-three-unsurrendered-spires-of-mine")!,
                Slashlink("/the-whale-the-whale")!,
                Slashlink("/oh-all-ye-sweet-powers-of-air-now-hug-me-close")!,
                Slashlink("/stubbs-own-unwinking-eye")!,
                Slashlink("/pole-pointed-prow")!,
            ]
        )
        guard case let .merge(parent, child) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be merge, but was \(suggestion)"
            )
            return
        }
        XCTAssertEqual(
            parent,
            query
        )
        XCTAssertEqual(
            child,
            current
        )
    }
}
