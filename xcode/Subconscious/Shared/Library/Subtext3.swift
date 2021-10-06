//
//  Subtext3.swift
//  Subtext3
//
//  Created by Gordon Brander on 8/23/21.
//

import Foundation
import SwiftUI

/// Attempting to implement Subtext as a pure Range-based tokenizer
struct Subtext3: Equatable {
    struct Tokens {
        var wikilinks: [String.SubSequence] = []
        var headings: [String.SubSequence] = []
        var urls: [String.SubSequence] = []
    }

    static func tokenize(_ markup: String) -> Tokens {
        var tape = Tape(markup)
        var tokens = Tokens()
        while !tape.isExhausted() {
            tape.setStart()
            let curr = tape.consume()
            if curr == "[" && tape.consumeMatch("[") {
                tape.save()
                if let wikilink = consumeWikilink(
                    tape: &tape
                ) {
                    tokens.wikilinks.append(wikilink)
                } else {
                    tape.backtrack()
                }
            } else if curr == "#" && tape.consumeMatch(" ") {
                let heading = consumeHeading(tape: &tape)
                tokens.headings.append(heading)
            } else if curr == "h" && tape.consumeMatch("ttp://") {
                let url = consumeUntilSpace(tape: &tape)
                tokens.urls.append(url)
            }  else if curr == "h" && tape.consumeMatch("ttps://") {
                let url = consumeUntilSpace(tape: &tape)
                tokens.urls.append(url)
            }
        }
        return tokens
    }

    static func isWikilinkForbidden(_ subsequence: String.SubSequence) -> Bool {
        switch subsequence {
        case "[", "]", ".", "!":
            return true
        default:
            return false
        }
    }

    /// Consumes a wikilink up until it finds a close sequence.
    /// If no close sequence is found, returns nil.
    /// You probably want to use this with backtracking.
    static func consumeWikilink(
        tape: inout Tape<String>
    ) -> String.SubSequence? {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "]" && tape.consumeMatch("]") {
                return tape.subsequence
            } else if isWikilinkForbidden(curr) {
                return nil
            }
        }
        return nil
    }

    static func consumeHeading(
        tape: inout Tape<String>
    ) -> String.SubSequence {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return tape.subsequence
            }
        }
        return tape.subsequence
    }

    static func consumeUntilSpace(
        tape: inout Tape<String>
    ) -> String.SubSequence {
        while !tape.isExhausted() {
            let curr = tape.peek()
            if curr == nil || curr!.isWhitespace {
                return tape.subsequence
            }
            tape.advance()
        }
        return tape.subsequence
    }

    let markup: String
    let wikilinks: [String.SubSequence]
    let headings: [String.SubSequence]
    let urls: [String.SubSequence]

    init(_ markup: String) {
        self.markup = markup
        let tokens = Self.tokenize(markup)
        self.wikilinks = tokens.wikilinks
        self.headings = tokens.headings
        self.urls = tokens.urls
    }

    // Get wikilink labels, without the double brackets
    func wikilinkLabels() -> [String.SubSequence] {
        wikilinks.map({ wikilink in
            var wikilink = wikilink
            wikilink.removeFirst(2)
            wikilink.removeLast(2)
            return wikilink
        })
    }

    // Get the range of the wikilink enclosing this `String.Index`, if any.
    func wikilinkRangeEnclosing(
        _ index: String.Index
    ) -> String.SubSequence? {
        wikilinks.first(where: { sub in
            sub.indices.contains(index)
        })
    }

    func strip() -> String {
        var markup = self.markup
        for wikilink in wikilinks {
            var text = wikilink
            text.removeFirst(2)
            text.removeLast(2)
            markup.replaceSubrange(
                wikilink.startIndex..<wikilink.endIndex,
                with: text
            )
        }
        return markup
    }

    func renderMarkup(
        url: (String.SubSequence) -> String?
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: markup)
        // Set default styles for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.preferredFont(forTextStyle: .body),
            range: NSRange(markup.startIndex..<markup.endIndex, in: markup)
        )
        for label in wikilinkLabels() {
            let nsRange = NSRange(
                label.startIndex..<label.endIndex,
                in: markup
            )
            if let url = url(label) {
                attributedString.addAttribute(
                    .link,
                    value: url,
                    range: nsRange
                )
            }
        }
        for url in urls {
            let nsRange = NSRange(
                url.startIndex..<url.endIndex,
                in: markup
            )
            attributedString.addAttribute(
                .link,
                value: String(url),
                range: nsRange
            )
        }
        return attributedString
    }

    /// Append additional markup.
    /// Returns a new Subtext instance
    func appending(dom: Self) -> Self {
        Self(self.markup + dom.markup)
    }

    /// Append additional markup.
    /// Returns a new Subtext instance
    func appending(markup: String) -> Self {
        Self(self.markup + markup)
    }
}
