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
                return span.trimming(" ")
            case .empty(let span):
                return span
            case .quote(let span, _), .list(let span, _), .heading(let span):
                return span.dropFirst().trimming(" ")
            }
        }
    }

    struct Link: Hashable, Equatable, CustomStringConvertible {
        var span: Substring

        var description: String {
            String(span)
        }

        var url: URL? {
            URL(string: String(span))
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

        var url: URL? {
            let body = span.dropFirst().dropLast()
            return URL(string: String(body))
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

    /// One of the two link forms
    enum EntryLinkMarkup: Hashable, Equatable {
        case slashlink(Slashlink)
        case wikilink(Wikilink)

        /// Get sentence version of link (nice text).
        /// Used to create default content for note from link text.
        func toTitle() -> String? {
            switch self {
            case .wikilink(let wikilink):
                return wikilink.toTitle()
            case .slashlink(let slashlink):
                return slashlink.toTitle()
            }
        }
    }

    /// Consume a well-formed bracket link, or else backtrack
    private static func consumeBracketLink(
        tape: inout Tape<Substring>
    ) -> Substring? {
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

    /// Consume a well-formed bracket link, or else backtrack
    private static func consumeWikilink(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.save()
        while !tape.isExhausted() {
            // Brackets are not allowed in wikilink bodies
            if tape.consumeMatch("[") {
                tape.backtrack()
                return nil
            } else if tape.consumeMatch("]]") {
                return tape.cut()
            } else {
                tape.advance()
            }
        }
        tape.backtrack()
        return nil
    }

    /// Consume a well-formed italics run, or else backtrack
    private static func consumeBold(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.save()
        while !tape.isExhausted() {
            if tape.consumeMatch("*") {
                return tape.cut()
            } else {
                tape.advance()
            }
        }
        tape.backtrack()
        return nil
    }

    /// Consume a well-formed italics run, or else backtrack
    private static func consumeItalic(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.save()
        while !tape.isExhausted() {
            if tape.consumeMatch("_") {
                return tape.cut()
            } else {
                tape.advance()
            }
        }
        tape.backtrack()
        return nil
    }

    /// Consume a well-formed code run, or else backtrack
    private static func consumeCode(
        tape: inout Tape<Substring>
    ) -> Substring? {
        tape.save()
        while !tape.isExhausted() {
            if tape.consumeMatch("`") {
                return tape.cut()
            } else {
                tape.advance()
            }
        }
        tape.backtrack()
        return nil
    }

    /// Is character a valid URL character that is punctuation?
    /// For convenience, character is an optional type, since peek
    /// returns an optional type.
    private static func isPossibleTrailingPunctuation(
        character: Character?
    ) -> Bool {
        switch character {
        case ".", "?", "!", ",", ";", "|":
            return true
        case "'", "\"":
            return true
        case  "(", ")", "{", "}", "[", "]", "<", ">":
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

    /// Consume all non-space characters excluding trailing punctuation.
    private static func consumeAddressBody(
        tape: inout Tape<Substring>
    ) -> Substring {
        while !tape.isExhausted() {
            let c0 = tape.peek(offset: 0)
            let c1 = tape.peek(offset: 1)
            // If c0 is URL-valid punctuation, but is followed by a space
            // character, we treat it as terminal punctuation and ignore it.
            // Cut the tape and return.
            if
               isPossibleTrailingPunctuation(character: c0) &&
               isSpace(character: c1)
            {
                return tape.cut()
            }
            // If current character is trailing punctionation and the
            // one after that is end-of-tape, cut and return.
            else if isPossibleTrailingPunctuation(character: c0) && c1 == nil {
                return tape.cut()
            }
            // If c0 is a space we've reached the end of the address,
            // cut and return.
            else if isSpace(character: c0) {
                return tape.cut()
            }
            //
            else {
                tape.advance()
            }
        }
        return tape.cut()
    }

    /// Parse all inline forms within the line
    /// - Returns: an array of inline forms
    private static func parseInline(
        tape: inout Tape<Substring>
    ) -> [Inline] {
        var inline: [Inline] = []
        while !tape.isExhausted() {
            tape.start()
            if tape.isAtBeginning && tape.consumeMatch("/") {
                let span = consumeAddressBody(tape: &tape)
                inline.append(.slashlink(Slashlink(span: span)))
            } else if tape.consumeMatch(" /") {
                let span = consumeAddressBody(tape: &tape)
                let cleaned = span.dropFirst()
                inline.append(.slashlink(Slashlink(span: cleaned)))
            } else if tape.consumeMatch("<") {
                if let link = consumeBracketLink(tape: &tape) {
                    inline.append(.bracketlink(Bracketlink(span: link)))
                }
            } else if tape.consumeMatch("[[") {
                if let wikilink = consumeWikilink(tape: &tape) {
                    inline.append(.wikilink(Wikilink(span: wikilink)))
                }
            } else if tape.consumeMatch("https://") {
                let span = consumeAddressBody(tape: &tape)
                inline.append(.link(Link(span: span)))
            } else if tape.consumeMatch("http://") {
                let span = consumeAddressBody(tape: &tape)
                inline.append(.link(Link(span: span)))
            } else if tape.consumeMatch("*") {
                if let bold = consumeBold(tape: &tape) {
                    inline.append(.bold(Bold(span: bold)))
                }
            } else if tape.consumeMatch("_") {
                if let italic = consumeItalic(tape: &tape) {
                    inline.append(.italic(Italic(span: italic)))
                }
            } else if tape.consumeMatch("`") {
                if let code = consumeCode(tape: &tape) {
                    inline.append(.code(Code(span: code)))
                }
            } else {
                tape.advance()
            }
        }
        return inline
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
        } else if line == "" {
            return Block.empty(span: line)
        } else {
            var tape = Tape(line)
            let inline = parseInline(tape: &tape)
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

    let base: String
    let blocks: [Block]

    init(markup: String) {
        self.base = markup
        self.blocks = Self.parseLines(markup).map(Self.parseBlock)
    }
}

extension Subtext {
    private static func renderInlineAttributeOf(
        _ attributedString: NSMutableAttributedString,
        inline: Subtext.Inline,
        url: (EntryLink) -> URL?
    ) {
        switch inline {
        case let .link(link):
            if let url = link.url {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        link.span.range,
                        in: attributedString.string
                    )
                )
            }
        case let .bracketlink(bracketlink):
            if let url = bracketlink.url {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor(Color.tertiaryText),
                    range: NSRange(
                        bracketlink.span.range,
                        in: attributedString.string
                    )
                )
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        bracketlink.body().range,
                        in: attributedString.string
                    )
                )
            }
        case let .slashlink(slashlink):
            if
                let slug = Slug(formatting: String(describing: slashlink)),
                let url = url(EntryLink(slug: slug, title: slug.toTitle()))
            {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: NSRange(
                        slashlink.span.range,
                        in: attributedString.string
                    )
                )
            }
        case let .wikilink(wikilink):
            let text = String(wikilink.text)
            if
                let slug = Slug(formatting: text),
                let urlString = url(EntryLink(slug: slug, title: text))
            {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor(Color.tertiaryText),
                    range: NSRange(
                        wikilink.span.range,
                        in: attributedString.string
                    )
                )
                attributedString.addAttribute(
                    .link,
                    value: urlString,
                    range: NSRange(
                        wikilink.text.range,
                        in: attributedString.string
                    )
                )
            }
        case .bold(let bold):
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoBold,
                range: NSRange(
                    bold.span.range,
                    in: attributedString.string
                )
            )
        case .italic(let italic):
            attributedString.addAttribute(
                .font,
                value: UIFont.appTextMonoItalic,
                range: NSRange(
                    italic.span.range,
                    in: attributedString.string
                )
            )
        case .code(let code):
            attributedString.addAttribute(
                .backgroundColor,
                value: UIColor(Color.secondaryBackground),
                range: NSRange(
                    code.span.range,
                    in: attributedString.string
                )
            )
        }
    }

    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    static func renderAttributesOf(
        _ attributedString: NSMutableAttributedString,
        url: (EntryLink) -> URL?
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
            case .list(_, let inline):
                for inline in inline {
                    renderInlineAttributeOf(
                        attributedString,
                        inline: inline,
                        url: url
                    )
                }
            case .quote(let line, let inline):
                let nsRange = NSRange(line.range, in: dom.base)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.appTextMonoItalic,
                    range: nsRange
                )
                for inline in inline {
                    renderInlineAttributeOf(
                        attributedString,
                        inline: inline,
                        url: url
                    )
                }
            case .text(_, let inline):
                for inline in inline {
                    renderInlineAttributeOf(
                        attributedString,
                        inline: inline,
                        url: url
                    )
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

extension Subtext.Block {
    /// Get inline ranges from a block of any type
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

    /// Extract all wikilinks and slashlinks from inline
    var entryLinks: [EntryLink] {
        self.inline.compactMap({ inline in
            switch inline {
            case .slashlink(let slashlink):
                return Slug(formatting: String(slashlink.span)).map({ slug in
                    EntryLink(slug: slug)
                })
            case .wikilink(let wikilink):
                return EntryLink(title: String(wikilink.text))
            default:
                return nil
            }
        })
    }

    /// Extract all slashlinks from inline
    var slashlinks: [Subtext.Slashlink] {
        self.inline.compactMap({ inline in
            switch inline {
            case .slashlink(let slashlink):
                return slashlink
            default:
                return nil
            }
        })
    }

    /// Extract all wikilinks from inline
    var wikilinks: [Subtext.Wikilink] {
        self.inline.compactMap({ inline in
            switch inline {
            case .wikilink(let wikilink):
                return wikilink
            default:
                return nil
            }
        })
    }
}

extension Subtext {
    /// Get all inline markup from blocks
    var inline: [Inline] {
        blocks.flatMap({ block in block.inline })
    }

    /// Get all entry links from Subtext.
    /// Simple array. Does not de-duplicate.
    var entryLinks: [EntryLink] {
        blocks.flatMap({ block in block.entryLinks })
    }

    /// Get all slashlinks from Subtext.
    /// Simple array. Does not de-duplicate.
    var slashlinks: [Subtext.Slashlink] {
        blocks.flatMap({ block in block.slashlinks })
    }

    /// Get all wikilinks from Subtext.
    /// Simple array. Does not de-duplicate.
    var wikilinks: [Subtext.Wikilink] {
        blocks.flatMap({ block in block.wikilinks })
    }
}

extension Subtext {
    /// Get wikilink for index, if any
    func wikilinkFor(index: String.Index) -> Subtext.Wikilink? {
        self.wikilinks.first(where: { wikilink in
            wikilink.text.range.upperBound == index
        })
    }

    /// Get wikilink in markup for range.
    /// Range is typically a selection range, with wikilink being the
    /// one currently being edited/typed.
    func wikilinkFor(range nsRange: NSRange) -> Subtext.Wikilink? {
        guard let range = Range(nsRange, in: base) else {
            return nil
        }
        let wikilink = wikilinkFor(index: range.lowerBound)
        return wikilink
    }

    /// Get slashlink for index, if any
    func slashlinkFor(index: String.Index) -> Subtext.Slashlink? {
        self.slashlinks.first(where: { slashlink in
            slashlink.span.range.upperBound == index
        })
    }

    /// Get slashlink in markup for range.
    /// Range is typically a selection range, with slashlink being the
    /// one currently being edited/typed.
    func slashlinkFor(range nsRange: NSRange) -> Subtext.Slashlink? {
        guard let range = Range(nsRange, in: base) else {
            return nil
        }
        return slashlinkFor(index: range.lowerBound)
    }

    /// Get EntryLinkMarkup for index, if any
    func entryLinkFor(index: String.Index) -> Subtext.EntryLinkMarkup? {
        for markup in inline {
            switch markup {
            case .slashlink(let slashlink):
                if slashlink.span.range.upperBound == index {
                    return EntryLinkMarkup.slashlink(slashlink)
                }
                break
            case .wikilink(let wikilink):
                if wikilink.text.range.upperBound == index {
                    return EntryLinkMarkup.wikilink(wikilink)
                }
                break
            default:
                break
            }
        }
        return nil
    }

    func entryLinkFor(range nsRange: NSRange) -> Subtext.EntryLinkMarkup? {
        guard let range = Range(nsRange, in: base) else {
            return nil
        }
        return entryLinkFor(index: range.lowerBound)
    }
}
