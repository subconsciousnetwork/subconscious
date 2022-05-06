//
//  HeaderParser.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/3/22.
//

import Foundation

enum Parser {}

extension Parser {
    static func discardSpaces(_ tape: inout Tape) {
        while let next = tape.peek() {
            if next != " " {
                tape.start()
                return
            }
            tape.advance()
        }
    }

    static func discardLine(_ tape: inout Tape) {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                tape.start()
                return
            }
        }
    }

    static func parseHeaderName(
        _ tape: inout Tape
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

    static func parseHeaderValue(
        _ tape: inout Tape
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
        _ tape: inout Tape
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
        _ tape: inout Tape
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
        _ tape: inout Tape
    ) -> Bool {
        let next = tape.peek()
        if next != nil && next!.isNewline {
            tape.advance()
            tape.start()
            return true
        }
        return false
    }

    /// Parse headers from a substring.
    /// Handles missing headers, invalid headers, and no headers.
    /// - Returns a ParseState containing an array of headers (if any)
    static func parseHeaders(
        _ tape: inout Tape
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
