//
//  Tests_Subtext.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Subtext: XCTestCase {
    func testWikilinkParsing0() throws {
        let markup = """
        Let's test out some [[wikilinks]].
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[wikilinks]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing1() throws {
        let markup = """
        [[Wikilink]] leading the block.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks[0].inline[0]
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(inline0)")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[Wikilink]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing3() throws {
        let markup = """
        [[Wikilink]]! with some trailing punctuation.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        guard case let .wikilink(wikilink) = inline0 else {
            XCTFail("Expected wikilink but was \(String(describing: inline0))")
            return
        }
        XCTAssertEqual(
            String(describing: wikilink),
            "[[Wikilink]]",
            "Wikilink markup parses to wikilink"
        )
    }

    func testWikilinkParsing4() throws {
        let markup = """
        Here's a[[wikilink]]embedded in some text.
        """
        let dom = Subtext(markup: markup)
        let inline0 = dom.blocks.get(0)?.inline.get(0)
        XCTAssertEqual(
            inline0,
            nil,
            "Wikilink does not parse when embedded within word"
        )
    }
}
