//
//  Subtext4.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/29/21.
//

import Foundation
import SwiftUI

extension Substring {
    var range: Range<Substring.Index> {
        self.startIndex..<self.endIndex
    }
}

extension String {
    func replacingNewlineWithSpace() -> String {
        self.replacingOccurrences(
            of: "\\s",
            with: " ",
            options: .regularExpression
        )
    }
}

struct Subtext4: Equatable {
    struct Tape<T>
    where T: Collection,
          T.SubSequence: Equatable
    {
        private(set) var startIndex: T.Index
        var endIndex: T.Index {
            self.collection.endIndex
        }
        private(set) var currentIndex: T.Index
        private(set) var savedIndex: T.Index
        let collection: T

        init(_ collection: T, startIndex: T.Index? = nil) {
            self.collection = collection
            let start = startIndex ?? collection.startIndex
            self.startIndex = start
            self.currentIndex = start
            self.savedIndex = start
        }

        /// Returns the current subsequence
        var subsequence: T.SubSequence {
            collection[startIndex..<currentIndex]
        }

        func isExhausted() -> Bool {
            return self.currentIndex >= self.endIndex
        }

        /// Sets the start of the current range to the current index
        /// Generally called at the beginning of each loop.
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
                limitedBy: self.endIndex
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
                    limitedBy: self.endIndex
                ),
                let endIndex = collection.index(
                    currentIndex,
                    offsetBy: offset + 1,
                    limitedBy: self.endIndex
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
                limitedBy: self.endIndex
            ) {
                return collection[currentIndex..<endIndex]
            }
            return nil
        }
    }

    struct TextBlock: Hashable, Equatable {
        var line: Substring
        var body: Substring
    }

    struct HeadingBlock: Hashable, Equatable {
        var line: Substring
        var sigil: Substring
        var body: Substring
    }

    struct LinkBlock: Hashable, Equatable {
        var line: Substring
        var sigil: Substring
        var link: Substring
        var body: Substring
    }

    /// Blocks of multiple types
    /// Associating with a substring gives us access to both content and range information
    enum Block: Equatable {
        case text(TextBlock)
        case heading(HeadingBlock)
        case link(LinkBlock)

        /// Consumes everything up to, but not including newline
        static func consumeLine(tape: inout Tape<Substring>) -> Substring {
            tape.setStart()
            while !tape.isExhausted() {
                if tape.peek() == "\n" {
                    return tape.subsequence
                }
                tape.advance()
            }
            return tape.subsequence
        }

        /// Fast-forward past contiguous whitespace
        static func skipSpaces(tape: inout Tape<Substring>) {
            while !tape.isExhausted() {
                let next = tape.peek()!
                if !next.isWhitespace {
                    tape.setStart()
                    return
                }
                tape.advance()
            }
            tape.setStart()
            return
        }

        static func consumeLink(
            tape: inout Tape<Substring>
        ) -> Substring {
            tape.setStart()
            while !tape.isExhausted() {
                let next = tape.peek()
                if next == " " || next == "\n" {
                    return tape.subsequence
                }
                tape.advance()
            }
            return tape.subsequence
        }

        static func parse(line: Substring) -> Self {
            var tape = Tape(line)
            if tape.consumeMatch("#") {
                let sigil = tape.subsequence
                let body = consumeLine(tape: &tape)
                return Self.heading(
                    HeadingBlock(
                        line: line,
                        sigil: sigil,
                        body: body
                    )
                )
            } else if tape.consumeMatch("=>") {
                let sigil = tape.subsequence
                skipSpaces(tape: &tape)
                let link = consumeLink(tape: &tape)
                skipSpaces(tape: &tape)
                let body = consumeLine(tape: &tape)
                return Self.link(
                    LinkBlock(
                        line: line,
                        sigil: sigil,
                        link: link,
                        body: body
                    )
                )
            } else {
                let body = consumeLine(tape: &tape)
                return Block.text(
                    TextBlock(
                        line: line,
                        body: body
                    )
                )
            }
        }

        static func templateHeading(_ string: String) -> String {
            let body = string.replacingNewlineWithSpace()
            return "# \(body)"
        }

        static func templateLink(_ string: String) -> String {
            let body = string.replacingNewlineWithSpace()
            return "=> \(body)"
        }

        static func templateText(_ string: String) -> String {
            return string.replacingNewlineWithSpace()
        }

        func contains(_ index: Substring.Index) -> Bool {
            switch self {
            case .heading(let block):
                return block.line.range.contains(index)
            case .link(let block):
                return block.line.range.contains(index)
            case .text(let block):
                return block.line.range.contains(index)
            }
        }
    }

    private static func parseLine(tape: inout Tape<String>) -> Block {
        tape.setStart()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return Block.parse(line: tape.subsequence)
            }
        }
        return Block.parse(line: tape.subsequence)
    }

    /// Static property for empty document
    static let empty = Self(markup: "")

    let base: String
    let blocks: [Block]
    let cursor: String.Index?
    let selectedIndex: Array.Index?

    var selected: Block? {
        if let selectedIndex = selectedIndex {
            return blocks[selectedIndex]
        }
        return nil
    }

    init(
        markup: String,
        cursor: String.Index? = nil
    ) {
        var blocks: [Block] = []
        var selectedIndex: Array.Index?
        // Block that cursor is placed within
        var tape = Tape(markup)
        while !tape.isExhausted() {
            let block = Self.parseLine(tape: &tape)
            blocks.append(block)
            if cursor != nil && block.contains(cursor!) {
                selectedIndex = blocks.index(before: blocks.endIndex)
            }
        }
        self.base = markup
        self.blocks = blocks
        self.cursor = cursor
        self.selectedIndex = selectedIndex
    }

    init(
        markup: String,
        range: NSRange
    ) {
        let cursor = Range(range, in: markup)
        self.init(
            markup: markup,
            cursor: cursor?.lowerBound
        )
    }

//    func replaceSelectedWithLink(_ string: String) -> Self? {
//        if let selected = selected {
//            let body = Block.templateLink(string)
//            let next = self.base.replacingCharacters(
//                in: selected.range,
//                with: body
//            )
//            return .init(markup: next, cursor: self.cursor)
//        }
//        return nil
//    }

    /// Render markup verbatim with syntax highlighting and links
    func renderMarkup(url: (Substring) -> String?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: base)
        // Set default styles for entire string
        attributedString.addAttribute(
            .font,
            value: UIFont.appText,
            range: NSRange(base.startIndex..<base.endIndex, in: base)
        )
        for block in blocks {
            switch block {
            case let .link(block):
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor.appSecondaryText,
                    range: NSRange(block.sigil.range, in: base)
                )
                if let url = url(block.link) {
                    attributedString.addAttribute(
                        .link,
                        value: url,
                        range: NSRange(block.link.range, in: base)
                    )
                }
            case let .heading(block):
                attributedString.addAttribute(
                    .font,
                    value: UIFont.appTextBold,
                    range: NSRange(block.line.range, in: base)
                )
            default:
                break
            }
        }
        return attributedString
    }
}
