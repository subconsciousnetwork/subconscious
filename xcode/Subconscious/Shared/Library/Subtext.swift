//
//  Subtext.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/25/21.
//

import Foundation
import SwiftUI

struct Subtext: Hashable, Equatable {
    /// Implement custom equatable for Subtext.
    /// Since parsing is deterministic, we can simply compare base strings.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }

    /// Empty document
    static let empty = Self(markup: "")

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
                return span.trimming(" ").trimming("\n")
            case .empty(let span):
                return span
            case .quote(let span, _), .list(let span, _), .heading(let span):
                return span.dropFirst().trimming(" ").trimming("\n")
            }
        }
    }

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
    }

    enum Inline: Hashable, Equatable {
        case link(Link)
        case bracketlink(Bracketlink)
        case slashlink(Slashlink)
    }

    /// Consume a well-formed bracket link, or else backtrack
    private static func consumeBracketLink(tape: inout Tape<Substring>) -> Substring? {
        tape.save()
        while !tape.isExhausted() {
            if tape.consumeMatch(" ") {
                tape.backtrack()
                return nil
            } else if tape.consumeMatch(">") {
                return tape.cut()
            } else {
                tape.advance()
            }
        }
        tape.backtrack()
        return nil
    }

    /// Determine if character is ASCII alphanumeric.
    /// For convenience, character is an optional type, since peek
    /// returns an optional type.
    private static func isAlphanumericAscii(
        character: Character?
    ) -> Bool {
        guard let character = character else {
            return false
        }
        guard character.isASCII else {
            return false
        }
        return character.isLetter || character.isNumber
    }

    /// Determine if character can be part of a slashlink
    /// See https://github.com/gordonbrander/subtext/blob/main/specification.md#slashlinks
    /// For convenience, character is an optional type, since peek
    /// returns an optional type.
    private static func isURLCharacter(
        character: Character?
    ) -> Bool {
        (
            isAlphanumericAscii(character: character) ||
            character == "/" ||
            character == "-" ||
            character == "_" ||
            character == "~" ||
            character == "=" ||
            character == "&" ||
            character == "%" ||
            character == "+" ||
            character == "'" ||
            character == "$" ||
            character == "#" ||
            isURLPunctuationCharacter(character: character)
        )
    }

    /// Is character a valid URL character that is punctuation?
    /// For convenience, character is an optional type, since peek
    /// returns an optional type.
    private static func isURLPunctuationCharacter(
        character: Character?
    ) -> Bool {
        switch character {
        case ".", "?", "!", ",", ";":
            return true
        default:
            return false
        }
    }

    /// Check if character is space
    /// Currently this matches only against a minimal set of space characters.
    /// For convenience, character is an optional type, since peek
    /// returns an optional type.
    private static func isSpace(character: Character?) -> Bool {
        switch character {
        case " ", "\n":
            return true
        default:
            return false
        }
    }

    /// Consume tape until the end of the URL body.
    /// Returns Substring.
    private static func consumeURLBody(
        tape: inout Tape<Substring>
    ) -> Substring {
        while !tape.isExhausted() {
            let c0 = tape.peek(offset: 0)
            let c1 = tape.peek(offset: 1)
            // If c0 is URL-valid punctuation, but is followed by a space
            // character, we treat it as terminal punctuation and ignore it.
            // Cut the tape and return.
            if
               isURLPunctuationCharacter(character: c0) &&
               isSpace(character: c1)
            {
                return tape.cut()
            }
            // If c0 is a URL character (not followed by a space)
            // advance the tape.
            else if isURLCharacter(character: c0) {
                tape.advance()
            }
            // Otherwie we've reached the end of the URL.
            // Cut the tape and return.
            else {
                return tape.cut()
            }
        }
        return tape.cut()
    }

    /// Determine if character can be part of a slashlink
    /// See https://github.com/gordonbrander/subtext/blob/main/specification.md#slashlinks
    private static func isSlashlinkCharacter(
        character: Character
    ) -> Bool {
        (
            character.isLetter ||
            character.isNumber ||
            character == "-" ||
            character == "/"
        )
    }

    /// Consume tape until the end of the slashlink body.
    /// Returns Substring.
    private static func consumeSlashlinkBody(
        tape: inout Tape<Substring>
    ) -> Substring {
        while !tape.isExhausted() {
            // Consume slashlink body characters.
            // If character is not a slashlink body character,
            // that marks the end of the slashlink body.
            // We cut the tape and return.
            if !tape.consumeMatch(where: isSlashlinkCharacter) {
                return tape.cut()
            }
        }
        return tape.cut()
    }

    /// Consume one of the inline forms that is delimited by word boundaries.
    /// A word boundary is generally a preceding space, or beginning of input.
    /// Cuts tape before word boundary.
    /// Returns an Inline?
    private static func consumeInlineWordBoundaryForm(
        tape: inout Tape<Substring>
    ) -> Inline? {
        if tape.consumeMatch("<") {
            if let link = consumeBracketLink(tape: &tape) {
                return .bracketlink(Bracketlink(span: link))
            } else {
                return nil
            }
        } else if tape.consumeMatch("https://") {
            let span = consumeURLBody(tape: &tape)
            return .link(Link(span: span))
        } else if tape.consumeMatch("http://") {
            let span = consumeURLBody(tape: &tape)
            return .link(Link(span: span))
        } else if tape.consumeMatch("/") {
            let span = consumeSlashlinkBody(tape: &tape)
            return .slashlink(Slashlink(span: span))
        } else {
            return nil
        }
    }

    private static func parseInline(tape: inout Tape<Substring>) -> [Inline] {
        var inlines: [Inline] = []

        /// Capture word-boundary-delimited forms at beginning of line.
        tape.start()
        if let inline = consumeInlineWordBoundaryForm(tape: &tape) {
            inlines.append(inline)
        }

        while !tape.isExhausted() {
            tape.start()
            let curr = tape.consume()
            /// Capture word-boundary-delimited forms after space
            if curr == " " {
                tape.start()
                if let inline = consumeInlineWordBoundaryForm(tape: &tape) {
                    inlines.append(inline)
                }
            }
        }

        return inlines
    }

    private static func parseBlock(_ line: Substring) -> Block {
        if line.hasPrefix("#") {
            return Block.heading(span: line)
        } else if line.hasPrefix(">") {
            var tape = Tape(line)
            // Discard prefix
            tape.advance()
            let inline = parseInline(tape: &tape)
            return Block.quote(span: line, inline: inline)
        } else if line.hasPrefix("-") {
            var tape = Tape(line)
            // Discard prefix
            tape.advance()
            let inline = parseInline(tape: &tape)
            return Block.list(span: line, inline: inline)
        } else if line.isWhitespace {
            return Block.empty(span: line)
        } else {
            var tape = Tape(line)
            let inline = parseInline(tape: &tape)
            return Block.text(span: line, inline: inline)
        }
    }

    /// Parse a single line from tape, returning it
    private static func consumeLine(tape: inout Tape<String>) -> Substring {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return tape.cut()
            }
        }
        return tape.cut()
    }

    /// Splits lines in markup, keeping line endings
    private static func parseLines(_ string: String) -> [Substring] {
        var tape = Tape(string)
        var lines: [Substring] = []
        while !tape.isExhausted() {
            let line = consumeLine(tape: &tape)
            lines.append(line)
        }
        return lines
    }

    let base: String
    let blocks: [Block]

    init(markup: String) {
        self.base = markup
        self.blocks = Self.parseLines(markup).map(Self.parseBlock)
    }
}

extension Subtext {
    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    static func renderAttributesOf(
        _ attributedString: NSMutableAttributedString,
        url: (String) -> String?
    ) {
        let dom = Subtext(markup: attributedString.string)

        // Get range of all text, using new Swift NSRange constructor
        // that takes a Swift range which knows how to handle Unicode
        // glyphs correctly.
        let baseNSRange = NSRange(
            dom.base.startIndex...,
            in: dom.base
        )

        // Set default font for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.appTextMono,
            range: baseNSRange
        )

        // Set line-spacing for entire string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = AppTheme.lineSpacing
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: baseNSRange
        )

        // Set text color
        attributedString.addAttribute(
            .foregroundColor,
            value: UIColor(Color.text),
            range: baseNSRange
        )

        for block in dom.blocks {
            switch block {
            case .empty:
                break
            case let .heading(line):
                let nsRange = NSRange(line.range, in: dom.base)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.appTextMonoBold,
                    range: nsRange
                )
            case
                .list(_, let inline),
                .quote(_, let inline),
                .text(_, let inline):
                for inline in inline {
                    switch inline {
                    case let .link(link):
                        attributedString.addAttribute(
                            .link,
                            value: link.span,
                            range: NSRange(
                                link.span.range,
                                in: dom.base
                            )
                        )
                    case let .bracketlink(bracketlink):
                        attributedString.addAttribute(
                            .link,
                            value: bracketlink.body(),
                            range: NSRange(
                                bracketlink.body().range,
                                in: dom.base
                            )
                        )
                    case let .slashlink(slashlink):
                        if let url = url(String(slashlink.span)) {
                            attributedString.addAttribute(
                                .link,
                                value: url,
                                range: NSRange(
                                    slashlink.span.range,
                                    in: dom.base
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}

extension Subtext {
    /// A summary of a Subtext document, including title and excerpt
    struct Summary {
        var title: String?
        var excerpt: String?
    }

    /// Derive a short summary of a Subtext document.
    func summarize() -> Summary {
        let content = blocks.filter({ block in
            switch block {
            case .empty:
                return false
            default:
                return true
            }
        })
        return Summary(
            title: content.get(0).map({ block in String(block.body()) }),
            excerpt: content.get(1).map({ block in String(block.body()) })
        )
    }

    /// Derive a title
    func title() -> String {
        for block in blocks {
            return String(block.body())
        }
        return ""
    }
}

extension Subtext {
    /// Append another Subtext document
    func append(_ other: Subtext) -> Subtext {
        Subtext(markup: "\(self.base)\n\n\(other.base)")
    }
}

extension Sequence where Iterator.Element == Subtext.Inline {
    var slashlinks: [Subtext.Slashlink] {
        self.compactMap({ inline in
            switch inline {
            case .slashlink(let slashlink):
                return slashlink
            default:
                return nil
            }
        })
    }
}

extension Subtext {
    /// Get all slashlinks from Subtext
    /// Simple array. Does not de-duplicate.
    var slashlinks: [Slashlink] {
        blocks.flatMap({ block in
            block.inline.slashlinks
        })
    }
}

extension Subtext.Block {
    var inline: [Subtext.Inline] {
        switch self {
        case
            .text(_, let inline),
            .list(_, let inline),
            .quote(_, let inline):
            return inline
        default:
            return []
        }
    }
}

extension Subtext {
    func slashlinkForPosition(_ i: String.Index) -> Subtext.Slashlink? {
        let slashlinks: [Subtext.Slashlink] = self.blocks.flatMap({ block in
            block.inline.slashlinks
        })

        for slashlink in slashlinks {
            if slashlink.span.range.upperBound == i {
                return slashlink
            }
        }

        return nil
    }

    func slashlinkFor(range nsRange: NSRange) -> Subtext.Slashlink? {
        guard let range = Range(nsRange, in: base) else {
            return nil
        }
        return slashlinkForPosition(range.lowerBound)
    }
}
