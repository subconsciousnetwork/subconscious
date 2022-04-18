//
//  HeaderParser.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/18/22.
//

import Foundation

struct HeaderParser {
    struct Header {
        var name: Substring
        var value: Substring
    }

    /// Fast-forward to the end of the line
    private static func advanceToEndOfLine(
        tape: inout Tape<Substring>
    ) {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return
            }
        }
    }

    private static func parseHeaderKey(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let next = tape.peek()
            // If end of key, cut tape and return key
            if next == ":" {
                // Cut tape, getting key value
                let key = tape.cut()
                // Advance tape, discarding `:`
                tape.advance()
                return key
            }
            // Invalid! Header keys cannot contain spaces.
            // Throw away the rest of the line and return nil.
            else if next == " " {
                advanceToEndOfLine(tape: &tape)
                return nil
            }
            // Invalid! This header has no key delimiter.
            // Throw away the rest of the line and return nil.
            else if next == "\n" {
                advanceToEndOfLine(tape: &tape)
                return nil
            }
            // Character is part of key. Advance tape so it is part of our
            // tape range.
            else {
                tape.advance()
            }
        }
        // If we got to the end of the file without finding a valid header key,
        // return nil.
        return nil
    }

    /// Whitespace before the value is ignored.
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
    private static func parseHeader(tape: inout Tape<Substring>) -> Header? {
        guard let key = parseHeaderKey(tape: &tape) else {
            return nil
        }
        guard let value = parseHeaderValue(tape: &tape) else {
            return nil
        }
        return Header(name: key, value: value)
    }

    /// Splits lines in markup, keeping line endings
    private static func parseHeaders(_ string: String) -> [Header]? {
        var tape = Tape(string[...])
        var headers: [Header] = []
        // Sniff for first header. If it can't be parsed, stop.
        // We consider this a document without headers.
        guard let header = parseHeader(tape: &tape) else {
            return nil
        }
        headers.append(header)
        while !tape.isExhausted() {
            if let header = parseHeader(tape: &tape) {
                headers.append(header)
            }
        }
        return headers
    }

    let base: String
    let headers: [Header]

    init?(_ markup: String) {
        guard let headers = Self.parseHeaders(markup) else {
            return nil
        }
        self.base = markup
        self.headers = headers
    }
}
