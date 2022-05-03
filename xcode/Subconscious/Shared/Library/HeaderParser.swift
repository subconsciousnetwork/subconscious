//
//  HeaderParser.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/3/22.
//

import Foundation

/// A struct representing a single header (line)
struct Header: Hashable, Equatable {
    let base: Substring
    let name: Substring
    let value: Substring

    /// Initializer is private.
    /// Use `Header.parse` instead.
    private init(
        base: Substring,
        name: Substring,
        value: Substring
    ) {
        self.base = base
        self.name = name
        self.value = value
    }

    /// Advance past contiguous whitespace.
    private static func discardSpaces(
        tape: inout Tape<Substring>
    ) {
        while !tape.isExhausted() {
            let next = tape.peek()
            if next != " " {
                tape.start()
                return
            }
            tape.advance()
        }
    }

    /// Parse header name
    /// Called by `parse` at begining of header.
    private static func parseName(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            let next = tape.peek()
            // Invalid! Header keys cannot contain whitespace.
            if curr.isWhitespace {
                return nil
            }
            // Invalid! This header has no key delimiter.
            else if curr.isNewline {
                return nil
            }
            // Invalid! HTTP header keys must be ASCII
            else if !curr.isASCII {
                return nil
            }
            // If end of key, cut tape and return key
            else if next == ":" {
                // Cut tape, getting key value
                let key = tape.cut()
                // Advance tape, discarding `:`
                tape.advance()
                return key
            }
        }
        // If we got to the end of the file without finding a valid header key,
        // return nil.
        return nil
    }

    /// Parse the value portion of a header.
    /// Called by `parse` after `parseHeaderName`.
    private static func parseValue(
        tape: inout Tape<Substring>
    ) -> Substring? {
        // Discard leading spaces, per HTTP header spec
        discardSpaces(tape: &tape)
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isNewline {
                let value = tape.cut()
                // Discard newline and return
                return value.dropLast()
            }
        }
        // If we've reached the end of the tape, without encountering a newline
        // consider this the value.
        return tape.cut()
    }

    /// Parse a header from substring
    /// - Returns Header?
    static func parse(base: Substring) -> Self? {
        var tape = Tape(base)
        guard let name = parseName(tape: &tape) else {
            return nil
        }
        guard let value = parseValue(tape: &tape) else {
            return nil
        }
        return Self(
            base: base,
            name: name,
            value: value
        )
    }
}

struct MemoDocument<Body> {
    let headers: [Header]
    let body: Body

    private init(
        headers: [Header],
        body: Body
    ) {
        self.headers = headers
        self.body = body
    }

    static func parse(
        _ parseBody: (Substring) -> Body?
    ) -> Self? {
        
    }
}
