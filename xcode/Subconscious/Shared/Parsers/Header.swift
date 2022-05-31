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
        Self.normalizeName(self.name)
    }

    var description: String {
        "\(normalizedName): \(value)\n"
    }

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
                header.normalizedName == name
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

struct HeaderIndex: Hashable, CustomStringConvertible {
    private(set) var index: OrderedDictionary<String, String>

    init(_ headers: [Header] = []) {
        var headerIndex: OrderedDictionary<String, String> = [:]
        for header in headers {
            let name = header.normalizedName
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
            self.index[name] = newValue
        }
    }

    var description: String {
        index
            .map({ name, value in
                String(describing: Header(name: name, value: value))
            })
            .joined(separator: "")
            .appending("\n")
    }

    /// Merge headers together, returning a new HeaderIndex.
    /// In case of conflicts between header keys, `self` wins.
    func merge(_ index: HeaderIndex) -> Self {
        var this = self
        for (key, value) in self.index {
            if this.index[key] == nil {
                this.index[key] = value
            }
        }
        return this
    }

    /// Set a header value only if a header of the same name
    /// does not already exist.
    mutating func setDefault(name: String, value: String) {
        let name = Header.normalizeName(name)
        if self.index[name] == nil {
            self.index[name] = value
        }
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
