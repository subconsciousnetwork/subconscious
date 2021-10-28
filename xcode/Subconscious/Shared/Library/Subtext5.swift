//
//  Subtext5.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/25/21.
//

import Foundation
import SwiftUI

struct Subtext5 {
    enum Block {
        case text(span: Substring, inline: [Inline])
        case list(span: Substring, inline: [Inline])
        case quote(span: Substring, inline: [Inline])
        case heading(span: Substring)

        /// Returns the body of a block, without the leading sigil
        func body() -> Substring {
            switch self {
            case .text(let span, _):
                return span
            case .quote(let span, _), .list(let span, _), .heading(let span):
                return span.dropFirst()
            }
        }
    }

    struct Link {
        var span: Substring
    }

    struct Bracketlink {
        var span: Substring

        func body() -> Substring {
            span.dropFirst().dropLast()
        }
    }

    struct Slashlink {
        var span: Substring
    }

    enum Inline {
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
                tape.consume()
            }
        }
        tape.backtrack()
        return nil
    }

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
            tape.consumeUntil(" ")
            return .link(Link(span: tape.cut()))
        } else if tape.consumeMatch("http://") {
            tape.consumeUntil(" ")
            return .link(Link(span: tape.cut()))
        } else if tape.consumeMatch("/") {
            tape.consumeUntil(" ")
            return .slashlink(Slashlink(span: tape.cut()))
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

    private static func parseLine(_ line: Substring) -> Block {
        if line.hasPrefix("#") {
            return Block.heading(span: line)
        } else if line.hasPrefix(">") {
            var tape = Tape(line)
            // Discard prefix
            tape.consume()
            let inline = parseInline(tape: &tape)
            return Block.quote(span: line, inline: inline)
        } else if line.hasPrefix("-") {
            var tape = Tape(line)
            // Discard prefix
            tape.consume()
            let inline = parseInline(tape: &tape)
            return Block.list(span: line, inline: inline)
        } else {
            var tape = Tape(line)
            let inline = parseInline(tape: &tape)
            return Block.list(span: line, inline: inline)
        }
    }

    let base: String
    let blocks: [Block]

    init(markup: String) {
        self.base = markup
        self.blocks = markup.split(
            omittingEmptySubsequences: false,
            whereSeparator: \.isNewline
        ).map(Self.parseLine)
    }

    /// Render markup verbatim with syntax highlighting and links
    func renderMarkup(url: (String) -> String?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: base)
        // Set default styles for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.appText,
            range: NSRange(base.startIndex..<base.endIndex, in: base)
        )

        for block in blocks {
            switch block {
            case let .heading(line):
                let nsRange = NSRange(line.range, in: attributedString.string)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.appTextBold,
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
                                in: attributedString.string
                            )
                        )
                    case let .bracketlink(bracketlink):
                        attributedString.addAttribute(
                            .link,
                            value: bracketlink.body(),
                            range: NSRange(
                                bracketlink.body().range,
                                in: attributedString.string
                            )
                        )
                    case let .slashlink(slashlink):
                        if let url = url(String(slashlink.span)) {
                            attributedString.addAttribute(
                                .link,
                                value: url,
                                range: NSRange(
                                    slashlink.span.range,
                                    in: attributedString.string
                                )
                            )
                        }
                    }
                }
            }
        }

        return attributedString
    }
}
