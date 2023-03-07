//
//  Subtext.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/25/21.
//

import Foundation
import SwiftUI


struct Subtext: Hashable, Equatable, LosslessStringConvertible {
    let base: Substring
    let blocks: [Block]

    static func parse(markup: String) -> Self {
        return Self.init(markup: markup)
    }

    private init(
        base: Substring,
        blocks: [Block]
    ) {
        self.base = base
        self.blocks = blocks
    }


    /// Parse Subtext body from tape
    init(_ tape: inout Tape) {
        let base = tape.rest
        let blocks = Self.parseBlocks(&tape)
        self.init(base: base, blocks: blocks)
    }

    /// Parse Subtext body from string
    init(markup: String) {
        var tape = Tape(markup[...])
        self.init(&tape)
    }

    init?(_ description: String) {
        self.init(markup: description)
    }

    var description: String {
        String(base)
    }

    /// Implement custom equatable for Subtext.
    /// Since parsing is deterministic, we can simply compare base strings.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }

    /// Empty document
    static let empty = Subtext(markup: "")

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

        var text: Substring {
            span.dropFirst(1)
        }
        
        var description: String {
            String(span)
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

    /// One of the two wiki link forms
    enum Shortlink: Hashable, Equatable {
        case slashlink(Slashlink)
        case wikilink(Wikilink)

        func toTitle() -> String {
            switch self {
            case .slashlink(let slashlink):
                return String(slashlink.text)
            case .wikilink(let wikilink):
                return String(wikilink.text)
            }
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

    /// Parse all inline forms within the line
    /// - Returns: an array of inline forms
    private static func parseInline(
        tape: inout Tape
    ) -> [Inline] {
        var inline: [Inline] = []
        while !tape.isExhausted() {
            tape.start()
            if tape.consumeMatch(/(?:^|\s)((@[\w\d\-]+)?(\/[\w\d\-\/]+))/) {
                var substring = tape.cut()
                if isSpace(character: substring.first) {
                    substring.removeFirst()
                }
                if isPossibleTrailingPunctuation(character: substring.last) {
                    substring.removeLast()
                }
                inline.append(.slashlink(Slashlink(span: substring)))
            } else if tape.consumeMatch(/\<[^>]+>/) {
                let substring = tape.cut()
                inline.append(.bracketlink(Bracketlink(span: substring)))
            } else if tape.consumeMatch(/\[\[[^\[\]]+\]\]/) {
                let substring = tape.cut()
                inline.append(.wikilink(Wikilink(span: substring)))
            } else if tape.consumeMatch(/https?\:\/\/[^\s]+/) {
                var substring = tape.cut()
                if isPossibleTrailingPunctuation(character: substring.last) {
                    substring.removeLast()
                }
                inline.append(.link(Link(span: substring)))
            } else if tape.consumeMatch(/\*[^\*]+\*/) {
                let substring = tape.cut()
                inline.append(.bold(Bold(span: substring)))
            } else if tape.consumeMatch(/_[^_]+_/) {
                let substring = tape.cut()
                inline.append(.italic(Italic(span: substring)))
            } else if tape.consumeMatch(/`[^`]+`/) {
                let substring = tape.cut()
                inline.append(.code(Code(span: substring)))
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

    /// Parse all blocks from tape
    static func parseBlocks(_ tape: inout Tape) -> [Block] {
        Parser.parseLines(&tape, keepEnds: false).map(Self.parseBlock)
    }
}

extension Subtext {
    private static func renderInlineAttributeOf(
        _ attributedString: NSMutableAttributedString,
        inline: Subtext.Inline,
        url: (String, String) -> URL?
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
                    value: UIColor(Color.tertiaryLabel),
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
                let url = url(slug.description, slug.toTitle())
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
                let url = url(slug.description, text)
            {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor(Color.tertiaryLabel),
                    range: NSRange(
                        wikilink.span.range,
                        in: attributedString.string
                    )
                )
                attributedString.addAttribute(
                    .link,
                    value: url,
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
    private static func renderBlockAttributesOf(
        _ attributedString: NSMutableAttributedString,
        block: Subtext.Block,
        url: (String, String) -> URL?
    ) {
        switch block {
        case .empty:
            break
        case let .heading(line):
            let nsRange = NSRange(line.range, in: attributedString.string)
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
            let nsRange = NSRange(line.range, in: attributedString.string)
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

    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    static func renderAttributesOf(
        _ attributedString: NSMutableAttributedString,
        url: (String, String) -> URL?
    ) -> Subtext {
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
            value: UIColor(Color.primary),
            range: baseNSRange
        )
        
        for block in dom.blocks {
            renderBlockAttributesOf(attributedString, block: block, url: url)
        }
        
        return dom
    }
    
    /// Read markup in NSMutableAttributedString, and render as attributes.
    /// Resets all attributes on string, replacing them with style attributes
    /// corresponding to the semantic meaning of Subtext markup.
    func renderAttributedString(
        url: (String, String) -> URL?
    ) -> NSAttributedString {
        // Get range of all text, using new Swift NSRange constructor
        // that takes a Swift range which knows how to handle Unicode
        // glyphs correctly.
        let baseNSRange = NSRange(
            self.base.startIndex...,
            in: self.base
        )
        
        let attributedString = NSMutableAttributedString(
            string: self.description
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
            value: UIColor(Color.primary),
            range: baseNSRange
        )
        
        for block in self.blocks {
            Self.renderBlockAttributesOf(
                attributedString,
                block: block,
                url: url
            )
        }

        return attributedString
    }
}

extension Subtext {
    /// Derive an excerpt
    func excerpt() -> String {
        for block in blocks {
            switch block {
            case .empty:
                continue
            default:
                return String(block.body())
            }
        }
        return ""
    }
}

extension Subtext {
    /// Append another Subtext document
    func appending(_ other: Subtext) -> Subtext {
        Subtext(markup: "\(self.base)\n\(other.base)")
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
    var shortlinks: [Subtext.Shortlink] {
        self.inline.compactMap({ inline in
            switch inline {
            case .slashlink(let slashlink):
                return Subtext.Shortlink.slashlink(slashlink)
            case .wikilink(let wikilink):
                return Subtext.Shortlink.wikilink(wikilink)
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

    /// Get the set of slugs within a range of Subtext.
    /// Contains slugs for both wikilinks and slashlinks.
    var slugs: Set<Slug> {
        let slugs = blocks
            .flatMap({ block in block.shortlinks })
            .compactMap({ link in
                switch link {
                case .slashlink(let slashlink):
                    return Slug(String(slashlink.text))
                case .wikilink(let wikilink):
                    return Slug(formatting: String(wikilink.text))
                }
            })
        return Set(slugs)
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
    func shortlinkFor(index: String.Index) -> Subtext.Shortlink? {
        for markup in inline {
            switch markup {
            case .slashlink(let slashlink):
                if slashlink.span.range.upperBound == index {
                    return Shortlink.slashlink(slashlink)
                }
                break
            case .wikilink(let wikilink):
                if wikilink.text.range.upperBound == index {
                    return Shortlink.wikilink(wikilink)
                }
                break
            default:
                break
            }
        }
        return nil
    }

    func shortlinkFor(range nsRange: NSRange) -> Subtext.Shortlink? {
        guard let range = Range(nsRange, in: base) else {
            return nil
        }
        return shortlinkFor(index: range.lowerBound)
    }
}

extension Subtext {
    func block(forParagraph: NSTextParagraph) -> Block? {
        return blocks.last { b in
            guard let contentRange = forParagraph.paragraphContentRange else {
                return false
            }
            guard let tcm = forParagraph.textContentManager else {
                return false
            }
            
            guard let range: Range<String.Index> = Range(NSRange(contentRange, in: tcm), in: base) else {
                return false
            }
            return b.body().range.overlaps(range)
        }
    }
}
