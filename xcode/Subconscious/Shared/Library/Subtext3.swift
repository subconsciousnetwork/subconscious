//
//  Subtext3.swift
//  Subtext3
//
//  Created by Gordon Brander on 8/23/21.
//

import Foundation
import SwiftUI

/// Attempting to implement Subtext as a pure Range-based tokenizer
struct Subtext3 {
    struct Tape<T>
    where T: Collection,
          T.SubSequence: Equatable
    {
        private(set) var savedIndex: T.Index
        private(set) var startIndex: T.Index
        private(set) var currentIndex: T.Index
        let collection: T

        init(_ collection: T) {
            self.collection = collection
            self.startIndex = collection.startIndex
            self.currentIndex = collection.startIndex
            self.savedIndex = collection.startIndex
        }

        /// Returns the current subsequence
        var subsequence: T.SubSequence {
            collection[startIndex..<currentIndex]
        }

        func isExhausted() -> Bool {
            return self.currentIndex >= self.collection.endIndex
        }

        mutating func setStart() {
            startIndex = currentIndex
        }

        mutating func advance(_ offset: Int = 1) {
            self.collection.formIndex(
                after: &self.currentIndex
            )
        }

        mutating func save() {
            savedIndex = currentIndex
        }

        mutating func backtrack() {
            startIndex = savedIndex
            currentIndex = savedIndex
        }

        /// Move forward one element
        mutating func consume() -> T.SubSequence {
            let subsequence = collection[currentIndex...currentIndex]
            advance()
            return subsequence
        }

        /// Peek forward, and consume if match
        mutating func consumeMatch(_ subsequence: T.SubSequence) -> Bool {
            if let endIndex = collection.index(
                currentIndex,
                offsetBy: subsequence.count,
                limitedBy: collection.endIndex
            ) {
                if collection[currentIndex..<endIndex] == subsequence {
                    self.currentIndex = endIndex
                    return true
                }
            }
            return false
        }

        /// Get a single-item SubSequence offset by `forward` of the `currentStartIndex`.
        /// Returns a single-item SubSequence, or nil if offset is invalid.
        func peek(_ offset: Int = 0) -> T.SubSequence? {
            if
                let startIndex = collection.index(
                    currentIndex,
                    offsetBy: offset,
                    limitedBy: collection.endIndex
                ),
                let endIndex = collection.index(
                    currentIndex,
                    offsetBy: offset + 1,
                    limitedBy: collection.endIndex
                )
            {
                return collection[startIndex..<endIndex]
            }
            return nil
        }

        /// Peek forward by `offset`, returning a subsequence from `position` through `offset`,
        /// or from `position` through `endIndex`, whichever is smaller..
        func peek(next offset: Int) -> T.SubSequence? {
            if let endIndex = collection.index(
                currentIndex,
                offsetBy: offset,
                limitedBy: collection.endIndex
            ) {
                return collection[currentIndex..<endIndex]
            }
            return nil
        }
    }

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

    let base: String
    let wikilinks: [String.SubSequence]
    let headings: [String.SubSequence]
    let urls: [String.SubSequence]

    init(_ markup: String) {
        self.base = markup
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

    func renderMarkup(
        url: (String.SubSequence) -> String?
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: base)
        // Set default styles for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.preferredFont(forTextStyle: .body),
            range: NSRange(base.startIndex..<base.endIndex, in: base)
        )
        for label in wikilinkLabels() {
            let nsRange = NSRange(
                label.startIndex..<label.endIndex,
                in: base
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
                in: base
            )
            attributedString.addAttribute(
                .link,
                value: String(url),
                range: nsRange
            )
        }
        return attributedString
    }
}
