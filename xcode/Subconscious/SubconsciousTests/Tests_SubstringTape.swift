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
        /slashlink where is  /slashlink [[and here is a wikilink]] this/slashlink? Some *bold* and _italic text_ and who wants `code`?
        """
        let tokens = SubtextRegexParser.parse(markup)
        print("!!!", tokens)
    }
}
