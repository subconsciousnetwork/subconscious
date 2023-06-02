//
//  Tests_RecoveryPhrase.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 2/22/23.
//

import XCTest
@testable import Subconscious

final class Tests_RecoveryPhrase: XCTestCase {
    final class MockPasteboard: PasteboardProtocol {
        var sets: Int = 0
        var _string: String? = nil

        var string: String? {
            get { _string }
            set {
                self._string = newValue
                self.sets = self.sets + 1
            }
        }
    }

    func testSetPhrase() throws {
        let environment: RecoveryPhraseEnvironment = RecoveryPhraseEnvironment()

        let state = RecoveryPhraseModel()
        XCTAssertEqual(state.phrase, "")

        let update = RecoveryPhraseModel.update(
            state: state,
            action: .setPhrase("foo bar baz"),
            environment: environment
        )
        XCTAssertEqual(update.state.phrase, "foo bar baz", "Set phrase")
    }
    
}
