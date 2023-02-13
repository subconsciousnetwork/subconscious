//
//  Tests_DatabaseService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 6/7/22.
//

import XCTest
@testable import Subconscious

class Tests_DatabaseService: XCTestCase {
    func testCollateRenameSuggestionsRetitle() throws {
        let current = EntryLink(
            title: "Ye three unsurrendered spires of mine",
            audience: .public
        )!
        let query = EntryLink(
            title: "Ye Three Unsurrendered Spires of Mine",
            audience: .public
        )!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    title: "The whale, the whale",
                    audience: .public
                )!,
                EntryLink(
                    title: "Oh, all ye sweet powers of air, now hug me close",
                    audience: .public
                )!,
                EntryLink(
                    title: "Stubb's own unwinking eye",
                    audience: .public
                )!,
                EntryLink(
                    title: "Pole-pointed prow",
                    audience: .public
                )!,
            ]
        )
        guard case let .retitle(from, to) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be retitle, but was \(suggestion)"
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

    func testCollateRenameSuggestionsRetitleWithSelfInResults() throws {
        let current = EntryLink(
            title: "Ye three unsurrendered spires of mine",
            audience: .public
        )!
        let query = EntryLink(
            title: "Ye Three Unsurrendered Spires of Mine",
            audience: .public
        )!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    title: "Ye three unsurrendered spires of mine",
                    audience: .public
                )!,
                EntryLink(
                    title: "The whale, the whale",
                    audience: .public
                )!,
                EntryLink(
                    title: "Oh, all ye sweet powers of air, now hug me close",
                    audience: .public
                )!,
                EntryLink(
                    title: "Stubb's own unwinking eye",
                    audience: .public
                )!,
                EntryLink(
                    title: "Pole-pointed prow",
                    audience: .public
                )!,
            ]
        )
        guard case let .retitle(from, to) = suggestions[0] else {
            let suggestion = String(reflecting: suggestions[0])
            XCTFail(
                "First suggestion expected to be retitle, but was \(suggestion)"
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

    func testCollateRenameSuggestionsMove() throws {
        let current = EntryLink(
            title: "Ye three unsurrendered spires of mine",
            audience: .public
        )!
        let query = EntryLink(
            title: "The whale, the whale",
            audience: .public
        )!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                current,
                EntryLink(
                    title: "Oh, all ye sweet powers of air, now hug me close",
                    audience: .public
                )!,
                EntryLink(
                    title: "Stubb's own unwinking eye",
                    audience: .public
                )!,
                EntryLink(
                    title: "Pole-pointed prow",
                    audience: .public
                )!,
            ]
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
        let current = EntryLink(
            title: "Ye three unsurrendered spires of mine",
            audience: .public
        )!
        let query = EntryLink(
            title: "The whale, the whale",
            audience: .public
        )!
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    title: "Ye three unsurrendered spires of mine",
                    audience: .public
                )!,
                EntryLink(
                    title: "The whale, the whale",
                    audience: .public
                )!,
                EntryLink(
                    title: "Oh, all ye sweet powers of air, now hug me close",
                    audience: .public
                )!,
                EntryLink(
                    title: "Stubb's own unwinking eye",
                    audience: .public
                )!,
                EntryLink(
                    title: "Pole-pointed prow",
                    audience: .public
                )!,
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
