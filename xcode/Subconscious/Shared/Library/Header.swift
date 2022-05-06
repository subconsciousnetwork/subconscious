//
//  Header.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct Header: Hashable, Equatable {
    let nameSpan: Substring
    let valueSpan: Substring

    /// Private initialiser
    /// Use `Header.parse` instead
    private init(
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

    static func parseName(
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

    static func parseValue(
        _ tape: inout Tape
    ) -> Substring {
        Parser.discardSpaces(&tape)
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
    static func parse(
        _ tape: inout Tape
    ) -> Header? {
        tape.save()
        // Require header to have valid name.
        guard let name = parseName(&tape) else {
            tape.backtrack()
            return nil
        }
        let value = parseValue(&tape)
        return Header(name: name, value: value)
    }
}

/// A document with headers
struct Headers {
    let headers: [Header]
    let body: Substring

    private init(
        headers: [Header],
        body: Substring
    ) {
        self.headers = headers
        self.body = body
    }

    /// Parse headers from a substring.
    /// Handles missing headers, invalid headers, and no headers.
    /// - Returns a ParseState containing an array of headers (if any)
    static func parse(
        _ tape: inout Tape
    ) -> Self {
        // Sniff first line. If it is empty, there are no headers.
        guard !Parser.parseEmptyLine(&tape) else {
            return Self(
                headers: [],
                body: tape.rest
            )
        }
        // Sniff first line. If it is not a valid header,
        // then return empty headers
        guard let firstHeader = Header.parse(&tape) else {
            return Self(
                headers: [],
                body: tape.rest
            )
        }
        var headers: [Header] = [firstHeader]
        while !tape.isExhausted() {
            tape.start()
            if Parser.parseEmptyLine(&tape) {
                return Self(
                    headers: headers,
                    body: tape.rest
                )
            } else if let header = Header.parse(&tape) {
                headers.append(header)
            } else {
                Parser.discardLine(&tape)
            }
        }
        return Self(
            headers: headers,
            body: tape.rest
        )
    }
}
