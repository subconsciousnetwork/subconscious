//
//  Header.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation
import OrderedCollections

/// A header
struct Header: Hashable, CustomStringConvertible {
    let name: String
    let value: String

    init(
        name: String,
        value: String
    ) {
        self.name = Self.normalizeName(name)
        self.value = Self.normalizeValue(value)
    }

    var description: String {
        "\(name): \(value)\n"
    }

    /// Normalize name by capitalizing first letter of each dashed word
    /// and lowercasing the rest. E.g.
    ///
    /// content-type -> Content-Type
    /// TITLE -> Title
    ///
    /// Headers are case-insensitive. This normalization step lets us
    /// compare header keys in a case-insensitive way, and matches
    /// typical HTTP header naming conventions.
    static func normalizeName(
        _ string: String
    ) -> String {
        string
            .capitalized
            .replacingOccurrences(
                of: #"\s"#,
                with: "-",
                options: .regularExpression,
                range: nil
            )
    }

    /// Normalize header value, removing newlines.
    /// Headers are newline delimited, so you can't have newlines in them.
    static func normalizeValue(
        _ string: String
    ) -> String {
        string.replacingOccurrences(
            of: #"[\r\n]"#,
            with: " ",
            options: .regularExpression,
            range: nil
        )
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
struct Headers: Hashable, CustomStringConvertible, Sequence {
    var headers: [Header]

    init(headers: [Header]) {
        self.headers = headers
    }

    /// Get headers, rendered back out as a string
    var description: String {
        headers
            .map({ header in String(describing: header) })
            .joined(separator: "")
            .appending("\n")
    }

    /// Conform to Sequence
    func makeIterator() -> IndexingIterator<Array<Header>> {
        headers.makeIterator()
    }

    /// Get the first header matching a particular name (if any)
    /// - Returns Header?
    func first(named name: String) -> Header? {
        let name = Header.normalizeName(name)
        return headers.first(
            where: { header in
                header.name == name
            }
        )
    }

    /// Append a header
    mutating func append(_ header: Header) {
        self.headers.append(header)
    }

    /// An empty header struct that can be re-used
    static let empty = Headers(headers: [])

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

struct HeaderIndex: Hashable, Sequence, CustomStringConvertible {
    private(set) var index: OrderedDictionary<String, String>

    init(_ headers: [Header] = []) {
        var headerIndex: OrderedDictionary<String, String> = [:]
        for header in headers {
            let name = header.name
            if headerIndex[name] == nil {
                headerIndex[name] = header.value
            }
        }
        self.index = headerIndex
    }

    subscript(_ name: String) -> String? {
        get {
            let name = Header.normalizeName(name)
            return self.index[name]
        }
        set {
            let name = Header.normalizeName(name)
            guard let value = newValue else {
                self.index[name] = nil
                return
            }
            self.index[name] = Header.normalizeValue(value)
        }
    }

    /// Conform to Sequence
    func makeIterator() -> OrderedDictionary<String, String>.Iterator {
        index.makeIterator()
    }

    var description: String {
        index
            .map({ name, value in
                String(describing: Header(name: name, value: value))
            })
            .joined(separator: "")
            .appending("\n")
    }

    /// Set a header value only if a header of the same name
    /// does not already exist.
    /// - Returns the current value of the header
    @discardableResult mutating func setDefault(
        name: String,
        value defaultValue: String
    ) -> String {
        let name = Header.normalizeName(name)
        guard let value = self.index[name] else {
            self.index[name] = defaultValue
            return defaultValue
        }
        return value
    }

    /// Merge headers together, returning a new HeaderIndex.
    /// In case of conflicts between header keys, `self` wins.
    func merge(_ other: HeaderIndex) -> Self {
        var this = self
        for (name, value) in other {
            this.setDefault(name: name, value: value)
        }
        return this
    }

    static let empty = HeaderIndex()
}

extension Headers {
    init(_ index: HeaderIndex) {
        self.headers = index.index.map({ name, value in
            Header(
                name: String(describing: name),
                value: value
            )
        })
    }
}

extension HeaderIndex {
    init(_ headers: Headers) {
        self.init(headers.headers)
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
