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
    static func parse(_ base: Substring) -> Self? {
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

struct Toggle<T> where T: Equatable {
    enum State {
        case on
        case off
    }
    var state: State = .on
    var control: T
    var reset: T?

    mutating func toggle(_ value: T) -> State {
        if value == control {
            self.state = .off
        }
        else if value == reset {
            self.state = .on
        }
        return self.state
    }
}

/// Lazily yields lines as substrings
struct LineIterator: IteratorProtocol {
    private var tape: Tape<Substring>

    init(_ base: Substring) {
        self.tape = Tape(base)
    }

    /// Get next line
    mutating func next() -> Substring? {
        guard !tape.isExhausted() else {
            return nil
        }
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isNewline {
                return tape.cut()
            }
        }
        return tape.cut()
    }
}

extension Substring {
    func lines() -> LineIterator {
        LineIterator(self)
    }
}

struct Headers {
    let span: Substring
    let headers: [Header]

    private init(
        span: Substring,
        headers: [Header]
    ) {
        self.span = span
        self.headers = headers
    }

    static func parse(_ base: Substring) -> Self? {
        var headers: [Header] = []
        var lines = base.lines()
        guard let firstLine = lines.next() else {
            return nil
        }
        guard let firstHeader = Header.parse(firstLine) else {
            return nil
        }
        headers.append(firstHeader)
        while let line = lines.next() {
            if line.isWhitespace {
                break
            }
            if let header = Header.parse(line) {
                headers.append(header)
            }
        }
//        return Self(
//            span: base,
//            headers: <#T##[Header]#>
//        )
    }
}
