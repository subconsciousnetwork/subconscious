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
        let slashlink = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let current = EntryLink(
            address: MemoAddress.public(slashlink),
            title: "Ye three unsurrendered spires of mine"
        )
        let query = EntryLink(
            address: MemoAddress.public(slashlink),
            title: "Ye Three Unsurrendered Spires of Mine"
        )
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/the-whale-the-whale")!
                    ),
                    title: "The whale, the whale"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink(
                            "/oh-all-ye-sweet-powers-of-air-now-hug-me-close"
                        )!
                    ),
                    title: "Oh, all ye sweet powers of air, now hug me close"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/stubbs-own-unwinking-eye")!
                    ),
                    title: "Stubb's own unwinking eye"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/pole-pointed-prow")!
                    ),
                    title: "Pole-pointed prow"
                ),
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
        let slashlink = Slashlink("/ye-three-unsurrendered-spires-of-mine")!
        let current = EntryLink(
            address: MemoAddress.public(slashlink),
            title: "Ye three unsurrendered spires of mine"
        )
        let query = EntryLink(
            address: MemoAddress.public(slashlink),
            title: "Ye Three Unsurrendered Spires of Mine"
        )
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    address: MemoAddress.public(slashlink),
                    title: "Ye three unsurrendered spires of mine"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/the-whale-the-whale")!
                    ),
                    title: "The whale, the whale"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink(
                            "/oh-all-ye-sweet-powers-of-air-now-hug-me-close"
                        )!
                    ),
                    title: "Oh, all ye sweet powers of air, now hug me close"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/stubbs-own-unwinking-eye")!
                    ),
                    title: "Stubb's own unwinking eye"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/pole-pointed-prow")!
                    ),
                    title: "Pole-pointed prow"
                ),
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
            address: MemoAddress.public(
                Slashlink("/ye-three-unsurrendered-spires-of-mine")!
            ),
            title: "Ye three unsurrendered spires of mine"
        )
        let query = EntryLink(
            address: MemoAddress.public(
                Slashlink("/the-whale-the-whale")!
            ),
            title: "The whale, the whale"
        )
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                current,
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink(
                            "/oh-all-ye-sweet-powers-of-air-now-hug-me-close"
                        )!
                    ),
                    title: "Oh, all ye sweet powers of air, now hug me close"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/stubbs-own-unwinking-eye")!
                    ),
                    title: "Stubb's own unwinking eye"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/pole-pointed-prow")!
                    ),
                    title: "Pole-pointed prow"
                ),
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
            address: MemoAddress.public(
                Slashlink("/ye-three-unsurrendered-spires-of-mine")!
            ),
            title: "Ye three unsurrendered spires of mine"
        )
        let query = EntryLink(
            address: MemoAddress.public(
                Slashlink("/the-whale-the-whale")!
            ),
            title: "The whale, the whale"
        )
        let suggestions = DatabaseService.collateRenameSuggestions(
            current: current,
            query: query,
            results: [
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/ye-three-unsurrendered-spires-of-mine")!
                    ),
                    title: "Ye three unsurrendered spires of mine"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/the-whale-the-whale")!
                    ),
                    title: "The whale, the whale"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink(
                            "/oh-all-ye-sweet-powers-of-air-now-hug-me-close"
                        )!
                    ),
                    title: "Oh, all ye sweet powers of air, now hug me close"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/stubbs-own-unwinking-eye")!
                    ),
                    title: "Stubb's own unwinking eye"
                ),
                EntryLink(
                    address: MemoAddress.public(
                        Slashlink("/pole-pointed-prow")!
                    ),
                    title: "Pole-pointed prow"
                ),
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
