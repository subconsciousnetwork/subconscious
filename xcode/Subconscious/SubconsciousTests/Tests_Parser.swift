//
//  Tests_HeaderParser.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 5/5/22.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

class Tests_Parser: XCTestCase {
    func testDiscardSpaces() throws {
        var tape = Tape(
            "   abcd"
        )
        Parser.discardSpaces(&tape)
        XCTAssertEqual(tape.rest, "abcd")
    }

    func testDiscardLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Title: Cybernetic self-systems
            
            Body text
            """
        )
        Parser.discardLine(&tape)
        XCTAssertEqual(
            tape.rest,
            """
            Title: Cybernetic self-systems
            
            Body text
            """
        )
    }

    func testParseLine() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Title: Cybernetic self-systems
            
            Body text
            """
        )
        let header = Parser.parseLine(&tape)
        XCTAssertEqual(header, "Content-Type: text/subtext\n")

        let title = Parser.parseLine(&tape)
        XCTAssertEqual(title, "Title: Cybernetic self-systems\n")

        let blank = Parser.parseLine(&tape)
        XCTAssertEqual(blank, "\n")

        let body = Parser.parseLine(&tape)
        XCTAssertEqual(body, "Body text")
    }

    func testParseLines() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Title: Cybernetic self-systems
            
            Body text
            """
        )
        let lines = Parser.parseLines(&tape)
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines[0], "Content-Type: text/subtext\n")
        XCTAssertEqual(lines[3], "Body text")
    }

    func testParseLinesDiscardEnds() throws {
        var tape = Tape(
            """
            Content-Type: text/subtext
            Title: Cybernetic self-systems
            
            Body text
            """
        )
        let lines = Parser.parseLines(&tape, keepEnds: false)
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines[0], "Content-Type: text/subtext")
        XCTAssertEqual(lines[3], "Body text")
    }
}
