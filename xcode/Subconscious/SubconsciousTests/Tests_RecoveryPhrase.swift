//
//  Tests_RecoveryPhrase.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/22/23.
//

import XCTest
@testable import Subconscious

final class Tests_RecoveryPhrase: XCTestCase {
    func testSetPhrase() throws {
        let environment: RecoveryPhraseEnvironment = RecoveryPhraseEnvironment()

        let state = RecoveryPhraseModel()
        XCTAssertEqual(state.phrase, nil)

        let phrase = RecoveryPhrase("foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap")
        let update = RecoveryPhraseModel.update(
            state: state,
            action: .setPhrase(phrase),
            environment: environment
        )
        XCTAssertEqual(update.state.phrase, phrase, "Set phrase")
    }
    
}
