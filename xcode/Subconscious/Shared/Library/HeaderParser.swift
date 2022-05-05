//
//  HeaderParser.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/3/22.
//

import Foundation

enum Parser {}

extension Parser {
    struct ParseState<Token>: Hashable
    where Token: Hashable
    {
        var token: Token
        var rest: Substring

        init(token: Token, rest: Substring) {
            self.token = token
            self.rest = rest
        }
    }
}

extension Parser.ParseState where Token == Substring {
    init(rest: Substring) {
        self.token = rest.prefix(0)
        self.rest = rest
    }
}

extension Parser {
    struct Header: Hashable, Equatable {
        var nameSpan: Substring
        var valueSpan: Substring

        init(
            name: Substring,
            value: Substring
        ) {
            self.nameSpan = name
            self.valueSpan = value
        }

        var name: String {
            nameSpan.lowercased()
        }

        var value: String {
            String(valueSpan)
        }
    }
}

extension Parser {
    static func advance(
        _ state: ParseState<Substring>
    ) -> ParseState<Substring> {
        let base = state.rest.base
        let rest = state.rest.dropFirst()
        return ParseState(
            token: base[state.token.startIndex..<rest.startIndex],
            rest: rest
        )
    }

    /// Parse until encountering a character
    static func parseUntil(
        _ state: ParseState<Substring>,
        match: (Character) -> Bool
    ) -> ParseState<Substring> {
        guard let next = state.rest.first else {
            return state
        }
        guard !match(next) else {
            return state
        }
        return parseUntil(advance(state), match: match)
    }

    static func discardSpaces(_ rest: Substring) -> Substring {
        if rest.first == " " {
            return discardSpaces(rest.dropFirst())
        }
        return rest
    }

    static func discardLine(_ rest: Substring) -> Substring {
        guard let next = rest.first else {
            return rest
        }
        guard !next.isNewline else {
            return rest.dropFirst()
        }
        return discardLine(rest.dropFirst())
    }

    static func parseHeaderName(
        _ state: ParseState<Substring>
    ) -> ParseState<Substring>? {
        guard let next = state.rest.first else {
            return nil
        }
        guard !next.isWhitespace else {
            return nil
        }
        guard !next.isNewline else {
            return nil
        }
        guard next.isASCII else {
            return nil
        }
        guard next != ":" else {
            return ParseState(
                token: state.token,
                rest: state.rest.dropFirst()
            )
        }
        return parseHeaderName(advance(state))
    }

    private static func parseHeaderValueRecursive(
        _ state: ParseState<Substring>
    ) -> ParseState<Substring>? {
        guard let next = state.rest.first else {
            return state
        }
        guard !next.isNewline else {
            return ParseState(
                token: state.token,
                rest: state.rest.dropFirst()
            )
        }
        return parseHeaderValueRecursive(advance(state))
    }

    static func parseHeaderValue(
        _ state: ParseState<Substring>
    ) -> ParseState<Substring>? {
        let rest = discardSpaces(state.rest)
        return parseHeaderValueRecursive(
            ParseState(
                rest: rest
            )
        )
    }

    /// Parse a single header line
    /// - Returns ParseState containing header
    static func parseHeader(
        _ rest: Substring
    ) -> ParseState<Header>? {
        guard let name = parseHeaderName(
            ParseState(rest: rest)
        ) else {
            return nil
        }
        guard let value = parseHeaderValue(
            ParseState(rest: name.rest)
        ) else {
            return nil
        }
        return ParseState(
            token: Header(name: name.token, value: value.token),
            rest: value.rest
        )
    }

    /// If the next character is a newline, drops it and returns rest.
    /// Otherwise returns nil.
    /// - Returns Substring
    static func parseEmptyLine(
        _ rest: Substring
    ) -> Substring? {
        if rest.first != nil && rest.first!.isNewline {
            return rest.dropFirst()
        }
        return nil
    }

    private static func parseHeadersRecursive(
        _ state: inout ParseState<[Header]>
    ) {
        if state.rest.isEmpty {
            return
        } else if let rest = parseEmptyLine(state.rest) {
            state.rest = rest
            return
        } else if let header = parseHeader(state.rest) {
            state.rest = header.rest
            state.token.append(header.token)
            return parseHeadersRecursive(&state)
        } else {
            state.rest = discardLine(state.rest)
            return parseHeadersRecursive(&state)
        }
    }

    /// Parse headers from a substring.
    /// Handles missing headers, invalid headers, and no headers.
    /// - Returns a ParseState containing an array of headers (if any)
    static func parseHeaders(
        _ rest: Substring
    ) -> ParseState<[Header]> {
        // Sniff first line. If it is empty, there are no headers.
        if let rest = parseEmptyLine(rest) {
            return ParseState(token: [], rest: rest)
        }
        // Sniff first line. If it is a valid header,
        // then kick off header parsing until first empty line.
        if let firstHeader = parseHeader(rest) {
            var state = ParseState(
                token: [firstHeader.token],
                rest: firstHeader.rest
            )
            parseHeadersRecursive(&state)
            return state
        }
        // Otherwise there are no headers
        return ParseState(token: [], rest: rest)
    }
}

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
