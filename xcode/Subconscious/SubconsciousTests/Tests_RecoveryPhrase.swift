//
//  Tests_RecoveryPhrase.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/29/23.
//

import XCTest
@testable import Subconscious

final class Tests_RecoveryPhrase: XCTestCase {
    func testValid() throws {
        let phrase = RecoveryPhrase("foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap")
        XCTAssertNotNil(phrase)
    }
    
    func testLowercases() throws {
        let phrase = RecoveryPhrase("FOO bAR bAZ bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap")
        XCTAssertEqual(
            phrase?.mnemonic,
            "foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap"
        )
    }

    func testInvalid() throws {
        let phrase = RecoveryPhrase("not a recovery phrase")
        XCTAssertNil(phrase)
    }
}
