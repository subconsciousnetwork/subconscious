//
//  SubstringTape.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/27/22.
//

import Foundation

struct SubstringTape {
    private(set) var savedIndex: Substring.Index
    private(set) var startIndex: Substring.Index
    private(set) var currentIndex: Substring.Index
    let base: Substring

    init(_ collection: Substring) {
        self.base = collection
        self.startIndex = collection.startIndex
        self.currentIndex = collection.startIndex
        self.savedIndex = collection.startIndex
    }

    func isExhausted() -> Bool {
        return self.currentIndex >= self.base.endIndex
    }

    /// Sets the start of the current range to the current index.
    /// Generally called at the beginning of parsing a token, to mark the
    /// beginning of the token range.
    mutating func start() {
        startIndex = currentIndex
    }

    /// Get current subsequence, and advance start index to current index.
    /// Conceptually like snipping off a piece of tape so that you have the
    /// piece up until the cut, and the cut becomes the new start of the tape.
    mutating func cut() -> Substring {
        let subsequence = base[startIndex..<currentIndex]
        startIndex = currentIndex
        return subsequence
    }

    mutating func save() {
        savedIndex = currentIndex
    }

    mutating func backtrack() {
        startIndex = savedIndex
        currentIndex = savedIndex
    }

    /// Move tape index forward by one
    mutating func advance() {
        _ = self.base.formIndex(
            &self.currentIndex,
            offsetBy: 1,
            limitedBy: base.endIndex
        )
    }

    /// Move forward one element.
    /// Returns `Element` at the `currentIndex` before advancing.
    mutating func consume() -> Character {
        let element = base[currentIndex]
        self.advance()
        return element
    }

    /// Get an item offset by `offset` from the `currentIndex`.
    /// - Returns a character, or nil if `offset` is invalid.
    func peek(offset: Int = 0) -> Character? {
        if
            let i = base.index(
                currentIndex,
                offsetBy: offset,
                limitedBy: base.endIndex
            )
        {
            if i < base.endIndex {
                return base[i]
            }
        }
        return nil
    }

    /// Parse tape until encountering a pattern
    mutating func parseUntil(
        _ pattern: String
    ) -> Substring {
        let string = base.base
        while !self.isExhausted() {
            if string[currentIndex...].range(
                of: pattern,
                options: [.regularExpression, .anchored]
            ) != nil {
                return self.cut()
            } else {
                self.advance()
            }
        }
        return self.cut()
    }

    /// A wrapper for NSTextCheckingResult that deals in valid
    /// Swift String ranges
    struct TextCheckingResult {
        let result: NSTextCheckingResult
        let base: String

        init(_ result: NSTextCheckingResult, in base: String) {
            self.base = base
            self.result = result
        }

        func group(at index: Int) -> Substring? {
            let nsRange = result.range(at: index)
            guard let range = Range(nsRange, in: self.base) else {
                return nil
            }
            return self.base[range]
        }
    }

    /// Parse next n characters if they match given regular expression
    mutating func parseMatch(
        _ pattern: NSRegularExpression
    ) -> TextCheckingResult? {
        self.start()
        let string = base.base
        guard let result = pattern.firstMatch(
            in: string,
            options: [.anchored, .withoutAnchoringBounds],
            range: NSRange(startIndex..., in: string)
        ) else {
            return nil
        }
        guard let range = Range(result.range, in: string) else {
            return nil
        }
        let group = TextCheckingResult(
            result,
            in: string
        )
        self.startIndex = range.upperBound
        self.currentIndex = range.upperBound
        return group
    }
}

protocol ParserProtocol {
    associatedtype Token
    func parse(_ tape: inout SubstringTape) -> Token?
}

extension ParserProtocol {
    func parse(input: Substring) -> Token? {
        var tape = SubstringTape(input)
        return self.parse(&tape)
    }
}

struct MatchParser<Token>: ParserProtocol {
    var pattern: NSRegularExpression
    var process: (SubstringTape.TextCheckingResult) -> Token?

    init(
        _ pattern: String,
        process: @escaping (SubstringTape.TextCheckingResult) -> Token?
    ) throws {
        self.pattern = try NSRegularExpression(pattern: pattern)
        self.process = process
    }

    func parse(_ tape: inout SubstringTape) -> Token? {
        if let result = tape.parseMatch(pattern) {
            return process(result)
        }
        return nil
    }
}

struct ScanningParser<Rule, Token>: ParserProtocol
where Rule: ParserProtocol, Rule.Token == Token
{
    var rules: [Rule]
    var skipFailedMatches: Bool

    init(_ rules: [Rule], skipFailedMatches: Bool = true) {
        self.rules = rules
        self.skipFailedMatches = skipFailedMatches
    }

    func parseNext(_ tape: inout SubstringTape) -> Token? {
        for rule in rules {
            if let token = rule.parse(&tape) {
                return token
            }
        }
        return nil
    }

    func parse(_ tape: inout SubstringTape) -> [Token]? {
        var stack: [Token] = []
        while !tape.isExhausted() {
            tape.start()
            if let token = parseNext(&tape) {
                stack.append(token)
            } else {
                if skipFailedMatches {
                    tape.advance()
                } else {
                    return nil
                }
            }
        }
        return stack
    }
}

struct SubtextParser {
    struct Link: Hashable, Equatable, CustomStringConvertible {
        var span: Substring
        var description: String {
            String(span)
        }
    }

    struct Bracketlink: Hashable, Equatable, CustomStringConvertible {
        var span: Substring
        var description: String {
            String(span)
        }
        func body() -> Substring {
            span.dropFirst().dropLast()
        }
    }

    struct Slashlink: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var description: String {
            String(span)
        }

        func toTitle() -> String? {
            Slug(formatting: String(span))?.toTitle()
        }
    }

    struct Wikilink: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var text: Substring {
            span.dropFirst(2).dropLast(2)
        }

        var description: String {
            String(span)
        }

        func toTitle() -> String? {
            String(text)
        }
    }

    struct Bold: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var text: Substring {
            span.dropFirst(1).dropLast(1)
        }

        var description: String {
            String(span)
        }
    }

    struct Italic: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var text: Substring {
            span.dropFirst(1).dropLast(1)
        }

        var description: String {
            String(span)
        }
    }

    struct Code: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var text: Substring {
            span.dropFirst(1).dropLast(1)
        }

        var description: String {
            String(span)
        }
    }

    enum Inline: Hashable, Equatable {
        case link(Link)
        case bracketlink(Bracketlink)
        case slashlink(Slashlink)
        case wikilink(Wikilink)
        case bold(Bold)
        case italic(Italic)
        case code(Code)
    }

    enum Block: Hashable, Equatable {
        case text(span: Substring, inline: [Inline])
        case list(span: Substring, inline: [Inline])
        case quote(span: Substring, inline: [Inline])
        case heading(span: Substring)
        case empty(span: Substring)

        /// Returns the body of a block, without the leading sigil
        func body() -> Substring {
            switch self {
            case .text(let span, _):
                return span.trimming(" ")
            case .empty(let span):
                return span
            case .quote(let span, _), .list(let span, _), .heading(let span):
                return span.dropFirst().trimming(" ")
            }
        }
    }

    static let slashlink = try! MatchParser(
        #"(^|\s)(\/[\w_\/\-]+)"#,
        process: { result in
            result.group(at: 2).map({ span in
                Inline.slashlink(Slashlink(span: span))
            })
        }
    )

    static let wikilink = try! MatchParser(
        #"\[\[[^\]]+\]\]"#,
        process: { result in
            result.group(at: 0).map({ span in
                Inline.wikilink(Wikilink(span: span))
            })
        }
    )

    static let bracketlink = try! MatchParser(
        #"<[^>]+>"#,
        process: { result in
            result.group(at: 0).map({ span in
                Inline.bracketlink(Bracketlink(span: span))
            })
        }
    )

    static let barelink = try! MatchParser(
        #"(https?:\/\/\S+\w)"#,
        process: { result in
            result.group(at: 1).map({ span in
                Inline.link(Link(span: span))
            })
        }
    )

    static let bold = try! MatchParser(
        #"\*[^\*]+\*"#,
        process: { result in
            result.group(at: 0).map({ span in
                Inline.bold(Bold(span: span))
            })
        }
    )

    static let italic = try! MatchParser(
        #"\_[^_]+_"#,
        process: { result in
            result.group(at: 0).map({ span in
                Inline.italic(Italic(span: span))
            })
        }
    )

    static let code = try! MatchParser(
        #"\`[^`]+`"#,
        process: { result in
            result.group(at: 0).map({ span in
                Inline.code(Code(span: span))
            })
        }
    )

    static let inline = ScanningParser(
        [
            slashlink,
            wikilink,
            bracketlink,
            barelink,
            bold,
            italic,
            code
        ]
    )

    private static func parseBlock(_ line: Substring) -> Block {
        if line.hasPrefix("#") {
            return Block.heading(span: line)
        } else if line.hasPrefix(">") {
            var tape = SubstringTape(line)
            // Discard prefix
            tape.advance()
            let inline = inline.parse(&tape) ?? []
            return Block.quote(span: line, inline: inline)
        } else if line.hasPrefix("-") {
            var tape = SubstringTape(line)
            // Discard prefix
            tape.advance()
            let inline = inline.parse(&tape) ?? []
            return Block.list(span: line, inline: inline)
        } else if line == "" {
            return Block.empty(span: line)
        } else {
            var tape = SubstringTape(line)
            let inline = inline.parse(&tape) ?? []
            return Block.text(span: line, inline: inline)
        }
    }

    /// Splits lines in markup, keeping line endings
    private static func parseLines(_ string: String) -> [Substring] {
        string.split(
            maxSplits: Int.max,
            omittingEmptySubsequences: false,
            whereSeparator: \.isNewline
        )
    }

    func parse(markup: String) -> [Block] {
        Self.parseLines(markup).map(Self.parseBlock)
    }
}
