//
//  Header.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct Header: Hashable, Equatable {
    var name: String
    var value: String

    init(
        name: String,
        value: String
    ) {
        self.name = name
        self.value = value
    }

    var normalizedName: String {
        name.lowercased()
    }

    func render() -> String {
        "\(name): \(value)\n"
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
        return Header(
            name: String(name),
            value: String(value)
        )
    }
}

/// A document with headers
struct Headers {
    var headers: [Header]
    var body: String

    /// Get headers and body, rendered back out as a string
    func render() -> String {
        let head = headers
            .map({ header in header.render() })
            .joined(separator: "")
        return """
        \(head)
        \(body)
        """
    }

    /// Get the first header matching a particular name (if any)
    /// - Returns Header?
    func first(named name: String) -> Header? {
        let name = name.lowercased()
        return headers.first(where: { header in header.name == name })
    }

    /// Remove all headers matching a particular name
    mutating func removeAll(named name: String) {
        self.headers.removeAll(
            where: { header in header.normalizedName == name }
        )
    }

    /// Append a header
    mutating func append(_ header: Header) {
        self.headers.append(header)
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
                body: String(tape.rest)
            )
        }
        // Sniff first line. If it is not a valid header,
        // then return empty headers
        guard let firstHeader = Header.parse(&tape) else {
            return Self(
                headers: [],
                body: String(tape.rest)
            )
        }
        var headers: [Header] = [firstHeader]
        while !tape.isExhausted() {
            tape.start()
            if Parser.parseEmptyLine(&tape) {
                return Self(
                    headers: headers,
                    body: String(tape.rest)
                )
            } else if let header = Header.parse(&tape) {
                headers.append(header)
            } else {
                Parser.discardLine(&tape)
            }
        }
        return Self(
            headers: headers,
            body: String(tape.rest)
        )
    }

    static func parse(markup: String) -> Self {
        var tape = Tape(markup[...])
        return parse(&tape)
    }
}
