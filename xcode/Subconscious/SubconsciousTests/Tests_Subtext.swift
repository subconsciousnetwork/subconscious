//
//  Tests_Subtext.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/11/22.
//

import XCTest
@testable import Subconscious

class Tests_Subtext: XCTestCase {
    func testWikilinks() {
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
}
