//
//  HeaderParser.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/18/22.
//

import Foundation

struct HeaderParser {
    struct Header {
        var key: Substring
        var value: Substring
    }

    private static func parseHeaderKey(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == ":" {
                return tape.cut()
            }
        }
        return nil
    }

    private static func parseHeaderValue(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return tape.cut()
            }
        }
        return nil
    }

    /// Parse a single line from tape, returning it
    private static func parseHeader(_ line: Substring) -> Header? {
        var tape = Tape(line)
        guard let key = parseHeaderKey(tape: &tape) else {
            return nil
        }
        guard let value = parseHeaderValue(tape: &tape) else {
            return nil
        }
        return Header(key: key, value: value)
    }

    /// Parse a single line from tape, returning it
    private static func consumeLine(tape: inout Tape<String>) -> Substring {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return tape.cut()
            }
        }
        return tape.cut()
    }

    /// Splits lines in markup, keeping line endings
    private static func parseLines(_ string: String) -> [Substring] {
        var tape = Tape(string)
        var lines: [Substring] = []
        while !tape.isExhausted() {
            let line = consumeLine(tape: &tape)
            if line == "\n" {
                return lines
            }
            lines.append(line)
        }
        return lines
    }

    let base: String
    let headers: [Header]

    init(_ markup: String) {
        let headers = Self.parseLines(markup).compactMap(Self.parseHeader)
        self.base = markup
        self.headers = headers
    }
}
