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

    static func discardSpaces(_ tape: inout Tape<Substring>) {
        while let next = tape.peek() {
            if next != " " {
                tape.start()
                return
            }
            tape.advance()
        }
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

    static func discardLine(_ tape: inout Tape<Substring>) {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                tape.start()
                return
            }
        }
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

    static func parseHeaderName(
        _ tape: inout Tape<Substring>
    ) -> Substring? {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isWhitespace {
                return nil
            } else if curr.isNewline {
                return nil
            } else if !curr.isASCII {
                return nil
            } else if curr == ":" {
                var name = tape.cut()
                name.removeLast()
                return name
            }
        }
        return nil
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

    static func parseHeaderValue(
        _ tape: inout Tape<Substring>
    ) -> Substring {
        discardSpaces(&tape)
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isNewline {
                let value = tape.cut()
                return value.dropLast()
            }
        }
        return tape.cut()
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

    /// Parse a single header line
    /// - Returns ParseState containing header
    static func parseHeader(
        _ tape: inout Tape<Substring>
    ) -> Header? {
        tape.save()
        // Require header to have valid name.
        guard let name = parseHeaderName(&tape) else {
            tape.backtrack()
            return nil
        }
        let value = parseHeaderValue(&tape)
        return Header(name: name, value: value)
    }

    /// If the next character is a newline, drops it and returns .
    /// Otherwise returns nil.
    /// - Returns Substring
    static func consumeEmptyLine(
        _ tape: inout Tape<Substring>
    ) -> Bool {
        let next = tape.peek()
        if next != nil && next!.isNewline {
            tape.advance()
            return true
        }
        return false
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

    /// If the next character is a newline, drops it and returns rest.
    /// Otherwise returns nil.
    /// - Returns Substring
    static func parseEmptyLine(
        _ tape: inout Tape<Substring>
    ) -> Bool {
        let next = tape.peek()
        if next != nil && next!.isNewline {
            tape.advance()
            tape.start()
            return true
        }
        return false
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

    /// Parse headers from a substring.
    /// Handles missing headers, invalid headers, and no headers.
    /// - Returns a ParseState containing an array of headers (if any)
    static func parseHeaders(
        _ tape: inout Tape<Substring>
    ) -> Headers {
        // Sniff first line. If it is empty, there are no headers.
        guard !parseEmptyLine(&tape) else {
            return Headers(headers: [])
        }
        // Sniff first line. If it is not a valid header,
        // then return empty headers
        guard let firstHeader = parseHeader(&tape) else {
            return Headers(headers: [])
        }
        var headers: [Header] = [firstHeader]
        while !tape.isExhausted() {
            tape.start()
            if parseEmptyLine(&tape) {
                return Headers(headers: headers)
            } else if let header = parseHeader(&tape) {
                headers.append(header)
            } else {
                discardLine(&tape)
            }
        }
        return Headers(headers: headers)
    }
}

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

struct Headers {
    var headers: [Header]
}
