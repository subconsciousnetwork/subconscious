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
            } else if curr == "\n" {
                return nil
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
    private static func parseHeader(tape: inout Tape<Substring>) -> Header? {
        guard let key = parseHeaderKey(tape: &tape) else {
            return nil
        }
        guard let value = parseHeaderValue(tape: &tape) else {
            return nil
        }
        return Header(key: key, value: value)
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
