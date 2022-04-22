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
        tape: inout Tape<String>
    ) {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isNewline {
                return
            }
        }
    }

    /// Advance past contiguous whitespace.
    /// Useful for moving past a range of space.
    private static func advancePastSpaces(
        tape: inout Tape<String>
    ) {
        while !tape.isExhausted() {
            let next = tape.peek()
            if next == " " {
                tape.advance()
            } else {
                return
            }
        }
    }

    private static func parseHeaderKey(
        tape: inout Tape<String>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let next = tape.peek()!
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
            else if next.isNewline {
                advanceToEndOfLine(tape: &tape)
                return nil
            }
            // Invalid! HTTP header keys must be ASCII
            else if !next.isASCII {
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
        tape: inout Tape<String>
    ) -> Substring? {
        // Discard leading space, per spec
        advancePastSpaces(tape: &tape)
        // Mark tape start
        tape.start()
        while !tape.isExhausted() {
            let next = tape.peek()!
            if next.isNewline {
                let value = tape.cut()
                // Throw away newline
                tape.advance()
                return value
            } else {
                tape.advance()
            }
        }
        return nil
    }

    /// Parse a single line from tape, returning it
    private static func parseHeader(tape: inout Tape<String>) -> Header? {
        guard let key = parseHeaderKey(tape: &tape) else {
            return nil
        }
        guard let value = parseHeaderValue(tape: &tape) else {
            return nil
        }
        return Header(name: key, value: value)
    }

    /// Splits lines in markup, keeping line endings
    static func parse(_ text: String) -> Self {
        var tape = Tape(text)
        var headers: [Header] = []
        // Sniff first line for header. If it can't be parsed as a header, stop.
        // We consider this a document without headers.
        guard let header = parseHeader(tape: &tape) else {
            // Return empty header struct
            return Self(
                string: tape.collection,
                headerPart: tape.collection[text.startIndex..<text.startIndex],
                headers: []
            )
        }
        headers.append(header)
        while !tape.isExhausted() {
            let next = tape.peek()
            // First empty line ends header parsing
            // Since we are at the beginning of a line, if the next character
            // is a newline, then this is an empty line.
            if next != nil && next!.isNewline {
                return Self(
                    string: tape.collection,
                    headerPart: tape.collection[
                        tape.collection.startIndex..<tape.currentIndex
                    ],
                    headers: headers
                )
            } else if let header = parseHeader(tape: &tape) {
                headers.append(header)
            }
        }
        return Self(
            string: tape.collection,
            headerPart: tape.collection[
                tape.collection.startIndex..<tape.currentIndex
            ],
            headers: headers
        )
    }

    let string: String
    let headerPart: Substring
    let headers: [Header]

    /// Call `HeaderParser.parse` to get an instance.
    /// Initializer is private, since all of these fields need to be
    /// constructed via a parse.
    private init(
        string: String,
        headerPart: Substring,
        headers: [Header]
    ) {
        self.string = string
        self.headerPart = headerPart
        self.headers = headers
    }
}
