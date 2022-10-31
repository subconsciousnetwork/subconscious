//
//  Header.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/6/22.
//

import Foundation
import OrderedCollections

/// A header
struct Header: Hashable, CustomStringConvertible, Codable {
    let name: String
    let value: String

    init(
        name: String,
        value: String
    ) {
        self.name = Self.normalizeName(name)
        self.value = Self.normalizeValue(value)
    }

    /// Parse a single header line
    /// - Returns ParseState containing header
    init?(
        _ tape: inout Tape
    ) {
        tape.save()
        // Require header to have valid name.
        guard let name = Self.parseName(&tape) else {
            tape.backtrack()
            return nil
        }
        let value = Self.parseValue(&tape)
        self.init(
            name: String(name),
            value: String(value)
        )
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
}

typealias Headers = Array<Header>

extension Headers {
    /// Parse headers from a substring.
    /// Handles missing headers, invalid headers, and no headers.
    /// - Returns a ParseState containing an array of headers (if any)
    init(
        _ tape: inout Tape
    ) {
        // Sniff first line. If it is empty, there are no headers.
        guard !Parser.parseEmptyLine(&tape) else {
            self.init()
            return
        }
        // Sniff first line. If it is not a valid header,
        // then return empty headers
        guard let firstHeader = Header(&tape) else {
            self.init()
            return
        }
        var headers: [Header] = [firstHeader]
        while !tape.isExhausted() {
            tape.start()
            if Parser.parseEmptyLine(&tape) {
                self.init(headers)
                return
            } else if let header = Header(&tape) {
                headers.append(header)
            } else {
                Parser.discardLine(&tape)
            }
        }
        self.init(headers)
        return
    }

    init(markup: String) {
        var tape = Tape(markup[...])
        self.init(&tape)
    }
}

extension Headers {
    /// Get headers, rendered back out as a string
    var text: String {
        self
            .map({ header in String(describing: header) })
            .joined(separator: "")
            .appending("\n")
    }

    /// Get the value of the first header matching a particular name (if any)
    /// - Returns String?
    func get(first name: String) -> String? {
        let name = Header.normalizeName(name)
        return self
            .first(where: { header in header.name == name })
            .map({ header in header.value })
    }

    /// Get the value of the first header
    func get<T>(with map: (String) -> T?, first name: String) -> T? {
        get(first: name).flatMap(map)
    }

    /// Get values for all headers named `name`
    func get(named name: String) -> [String] {
        let name = Header.normalizeName(name)
        return self
            .filter({ header in header.name == name })
            .map({ header in header.value })
    }

    /// Remove first header with name (if any).
    mutating func remove(first name: String) {
        guard let i = self.firstIndex(where: { existing in
            existing.name == name
        }) else {
            return
        }
        self.remove(at: i)
    }

    /// Remove duplicate headers from array, keeping only the first
    func removeDuplicates() -> Self {
        self.uniquing(with: \.name)
    }

    /// Merge headers.
    /// Duplicate headers from `other` are dropped.
    func merge(_ other: Headers) -> Self {
        var this = self
        this.append(contentsOf: other)
        return this.removeDuplicates()
    }

    /// Update header, either replacing the first existing header with the
    /// same key, or appending a new header to the list of headers.
    mutating func replace(_ header: Header) {
        guard let i = self.firstIndex(where: { existing in
            existing.name == header.name
        }) else {
            self.append(header)
            return
        }
        self[i] = header
    }

    /// Replace header.
    /// Updates value of first header with this name if it exists,
    /// or appends header with this name, if it doesn't.
    mutating func replace(name: String, value: String) {
        replace(Header(name: name, value: value))
    }

    /// Set a fallback for header. If header does not exist, it will set
    /// fallback content. Otherwise it will leave the value alone.
    mutating func fallback(
        name: String,
        value: String
    ) {
        // Do not set if value for this header already exists
        guard get(first: name) == nil else {
            return
        }
        replace(name: name, value: value)
    }

    /// Remove all headers with a given name
    func remove(named name: String) -> Self {
        let name = Header.normalizeName(name)
        return self.filter({ header in header.name != name })
    }
}

/// Helpers for certain "blessed" headers
extension Headers {
    /// Create headers instance with blessed fields
    init(
        contentType: String,
        modified: Date,
        created: Date,
        title: String
    ) {
        self.init()
        self.contentType(contentType)
        self.modified(modified)
        self.created(created)
        self.title(title)
    }
    
    func contentType() -> String? {
        get(first: "Content-Type")
    }
    
    mutating func contentType(_ contentType: String) {
        replace(name: "Content-Type", value: contentType)
    }
    
    func modified() -> Date? {
        get(with: Date.from, first: "Modified")
    }
    
    /// Get modified date or a default date (now)
    func modifiedOrDefault() -> Date {
        modified() ?? Date.epoch
    }
    
    mutating func modified(_ date: Date) {
        replace(
            name: "Modified",
            value: String.from(date)
        )
    }
    
    func created() -> Date? {
        get(with: Date.from, first: "Created")
    }
    
    /// Get created date or a default (Unix epoch)
    func createdOrDefault() -> Date {
        modified() ?? Date.epoch
    }
    
    mutating func created(_ date: Date) {
        replace(
            name: "Created",
            value: String.from(date)
        )
    }
    
    func title() -> String? {
        get(first: "Title")
    }
    
    mutating func title(_ title: String) {
        replace(
            name: "Title",
            value: title
        )
    }
    
    /// Mend blessed headers, providing fallbacks
    mutating func mend(
        contentType: ContentType = ContentType.subtext,
        title: String,
        modified: Date = Date.now,
        created: Date = Date.now
    ) {
        self.fallback(
            name: "Content-Type",
            value: contentType.rawValue
        )
        self.fallback(
            name: "Title",
            value: title
        )
        self.fallback(
            name: "Modified",
            value: String.from(modified)
        )
        self.fallback(
            name: "Created",
            value: String.from(created)
        )
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

    init(markup: String) {
        var tape = Tape(markup[...])
        let headers = Headers(&tape)
        let body = tape.rest
        self.init(
            headers: headers,
            body: body
        )
    }

    var description: String {
        "\(headers)\(body)"
    }
}
