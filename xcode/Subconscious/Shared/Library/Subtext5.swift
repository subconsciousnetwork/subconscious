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
        case text(line: Substring, inline: Inline)
        case list(line: Substring, inline: Inline)
        case quote(line: Substring, inline: Inline)
        case heading(line: Substring)

        /// Returns the body of a block, without the leading sigil
        func body() -> Substring {
            switch self {
            case .text(let line, _):
                return line
            case .quote(let line, _), .list(let line, _), .heading(let line):
                return line.dropFirst()
            }
        }
    }

    struct Inline {
        var links: [Substring] = []
        var bracketLinks: [Substring] = []
        var slashlinks: [Substring] = []
    }

    static func parseInline(tape: inout Tape<Substring>) -> Inline {
        var inline = Inline()
        while !tape.isExhausted() {
            tape.start()
            if tape.consumeMatch("https://") {
                tape.consumeUntil(" ")
                inline.links.append(tape.cut())
            } else if tape.consumeMatch("http://") {
                tape.consumeUntil(" ")
                inline.links.append(tape.cut())
            } else if tape.consumeMatch("<") {
                tape.consumeUntil(">")
                if tape.consumeMatch(">") {
                    inline.bracketLinks.append(tape.cut())
                }
            } else if tape.consumeMatch("/") {
                tape.consumeUntil(" ")
                inline.slashlinks.append(tape.cut())
            } else {
                tape.consume()
            }
        }
        return inline
    }

    static func parseLine(_ line: Substring) -> Block {
        if line.hasPrefix("#") {
            return Block.heading(line: line)
        } else if line.hasPrefix(">") {
            var tape = Tape(line)
            // Discard prefix
            tape.consume()
            let inline = parseInline(tape: &tape)
            return Block.quote(line: line, inline: inline)
        } else if line.hasPrefix("-") {
            var tape = Tape(line)
            // Discard prefix
            tape.consume()
            let inline = parseInline(tape: &tape)
            return Block.list(line: line, inline: inline)
        } else {
            var tape = Tape(line)
            let inline = parseInline(tape: &tape)
            return Block.list(line: line, inline: inline)
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
                for slashlink in inline.slashlinks {
                    if let url = url(String(slashlink)) {
                        attributedString.addAttribute(
                            .link,
                            value: url,
                            range: NSRange(
                                slashlink.range, in: attributedString.string
                            )
                        )
                    }

                }
                for link in inline.links {
                    attributedString.addAttribute(
                        .link,
                        value: link,
                        range: NSRange(link.range, in: attributedString.string)
                    )
                }

            }
        }

        return attributedString
    }
}
