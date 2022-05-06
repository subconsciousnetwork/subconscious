//
//  Tests_Tape.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/5/22.
//

import XCTest
@testable import Subconscious

class Tests_Tape: XCTestCase {
    func testTapeStart() throws {
        var tape = Tape("abcdefg")
        tape.advance()
        tape.advance()
        tape.start()
        XCTAssertEqual(tape.rest, "cdefg")
    }

    func testTapeConsume() throws {
        var tape = Tape("abcdefg")
        let char = tape.consume()
        XCTAssertEqual(char, "a")
    }

    func testTapeCut() throws {
        var tape = Tape("abcdefg")
        tape.advance()
        tape.advance()
        let result = tape.cut()
        XCTAssertEqual(result, "ab")
        XCTAssertEqual(tape.rest, "cdefg")
    }

    func testTapeIsExhausted() throws {
        var tape = Tape("ab")
        tape.advance()
        tape.advance()
        XCTAssertEqual(tape.isExhausted(), true)
    }

    func testTapeIsExhaustedEmpty() throws {
        let tape = Tape("")
        XCTAssertEqual(tape.isExhausted(), true)
    }

    func testTapeAdvanceTooFar() throws {
        var tape = Tape("ab")
        tape.advance()
        tape.advance()
        tape.advance()
        XCTAssertEqual(tape.currentIndex, tape.base.endIndex)
    }

    func testTapeAdvanceTooFarStart() throws {
        var tape = Tape("ab")
        tape.advance()
        tape.advance()
        tape.advance()
        tape.start()
        XCTAssertEqual(tape.rest, "")
    }

    func testTapeConsumeMatch() throws {
        var tape = Tape("abcdefg")
        let flag = tape.consumeMatch("ab")
        let value = tape.cut()
        XCTAssertEqual(flag, true)
        XCTAssertEqual(value, "ab")
        XCTAssertEqual(tape.rest, "cdefg")
    }

    func testTapeConsumeMatchNoMatch() throws {
        var tape = Tape("abcdefg")
        let flag = tape.consumeMatch("fg")
        XCTAssertEqual(flag, false)
        XCTAssertEqual(tape.rest, "abcdefg")
    }

    func testTapeBacktrack() throws {
        var tape = Tape("abcdefg")
        tape.advance()
        tape.save()
        tape.advance()
        tape.advance()
        let value = tape.cut()

        XCTAssertEqual(value, "abc")
        XCTAssertEqual(tape.rest, "defg")

        tape.backtrack()

        XCTAssertEqual(tape.rest, "bcdefg")
        XCTAssertEqual(tape.currentIndex, tape.rest.startIndex)
    }

}
