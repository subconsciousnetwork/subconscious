//
//  Header.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation

struct Header: Hashable, CustomStringConvertible {
    var name: String
    var value: String

    init(
        name: String,
        value: String
    ) {
        self.name = name
        self.value = value
    }

    /// Normalize name by capitalizing first letter of each dashed word
    /// and lowercasing the rest. E.g.
    ///
    /// content-type -> Content-Type
    /// TITLE -> Title
    ///
    /// Headers are case-insensitive, but this format is in keeping with
    /// typical HTTP header naming conventions.
    var normalizedName: String {
        name.capitalized
    }

    var description: String {
        "\(normalizedName): \(value)\n"
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

/// A collection of parsed HTTP-style headers
struct Headers: Hashable, CustomStringConvertible {
    var headers: [Header]

    /// Get headers, rendered back out as a string
    var description: String {
        headers
            .map({ header in String(describing: header) })
            .joined(separator: "")
            .appending("\n")
    }

    /// Get the first header matching a particular name (if any)
    /// - Returns Header?
    func first(named name: String) -> Header? {
        let name = name.capitalized
        return headers.first(where: { header in header.normalizedName == name })
    }

    /// Index header to dictionary.
    /// Duplicate headers will be ignored. First header wins.
    /// While duplicate headers are technically allowed by the HTTP spec for
    /// some header types (comma separated), we discourage this form.
    func toDictionary() -> Dictionary<String, String> {
        var index: Dictionary<String, String> = Dictionary()
        for header in headers {
            if index[header.normalizedName] == nil {
                index[header.normalizedName] = header.value
            }
        }
        return index
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
                headers: []
            )
        }
        // Sniff first line. If it is not a valid header,
        // then return empty headers
        guard let firstHeader = Header.parse(&tape) else {
            return Self(
                headers: []
            )
        }
        var headers: [Header] = [firstHeader]
        while !tape.isExhausted() {
            tape.start()
            if Parser.parseEmptyLine(&tape) {
                return Self(
                    headers: headers
                )
            } else if let header = Header.parse(&tape) {
                headers.append(header)
            } else {
                Parser.discardLine(&tape)
            }
        }
        return Self(
            headers: headers
        )
    }

    static func parse(markup: String) -> Self {
        var tape = Tape(markup[...])
        return parse(&tape)
    }
}

/// A combination of parsed headers and body part
/// Parses headers and retains body portion as a substring
struct HeadersEnvelope: CustomStringConvertible {
    var headers: Headers
    var body: Substring

    private init(
        headers: Headers,
        body: Substring
    ) {
        self.headers = headers
        self.body = body
    }

    var description: String {
        "\(headers)\(body)"
    }

    static func parse(markup: String) -> Self {
        var tape = Tape(markup[...])
        let headers = Headers.parse(&tape)
        let body = tape.rest
        return Self(
            headers: headers,
            body: body
        )
    }
}
