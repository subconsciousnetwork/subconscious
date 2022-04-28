//
//  Tests_SubstringTape.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/27/22.
//

import XCTest
@testable import Subconscious

class Tests_SubstringTape: XCTestCase {
    func testPerformanceExample() throws {
        let markup = """
        /slashlink-a  /slashlink-b [[and here is a wikilink]] and a https://example.com. Not/a-slashlink this /slashlink-c? And *here is some bold text* and _italic_ `code` But what hapens with a *broken bold?

        More subtext http://example.com
        """
        let tokens = SubtextParser().parse(markup: markup)
//        let tokens = SubtextRegexParser.parse(markup)
        print("!!!", tokens)
    }
}
