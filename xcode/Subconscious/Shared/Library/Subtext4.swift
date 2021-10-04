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

    /// Blocks of multiple types
    /// Associating with a substring gives us access to both content and range information
    enum Block: Equatable {
        case text(Substring)
        case heading(Substring)
        case link(Substring)

        static func parse(line: Substring) -> Self {
            if line.starts(with: "#") {
                return Block.heading(line)
            } else if line.starts(with: "&") {
                return Block.link(line)
            } else {
                return Block.text(line)
            }
        }

        static func templateHeading(_ string: String) -> String {
            let body = string.replacingNewlineWithSpace()
            return "# \(body)"
        }

        static func templateLink(_ string: String) -> String {
            let body = string.replacingNewlineWithSpace()
            return "& \(body)"
        }

        static func templateText(_ string: String) -> String {
            return string.replacingNewlineWithSpace()
        }

        func markup() -> Substring {
            switch self {
            case let .link(sub):
                return sub
            case let .heading(sub):
                return sub
            case let .text(sub):
                return sub
            }
        }

        func stripped() -> Substring {
            switch self {
            case let .link(sub):
                return sub.dropFirst(1)
            case let .heading(sub):
                return sub.dropFirst(1)
            case let .text(sub):
                return sub
            }
        }

        var range: Range<Substring.Index> {
            switch self {
            case let .text(sub):
                return sub.startIndex..<sub.endIndex
            case let .link(sub):
                return sub.startIndex..<sub.endIndex
            case let .heading(sub):
                return sub.startIndex..<sub.endIndex
            }
        }
    }

    private static func parseLine(tape: inout Tape<String>) -> Substring {
        tape.setStart()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                return tape.subsequence
            }
        }
        return tape.subsequence
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
            let line = Self.parseLine(tape: &tape)
            let block = Block.parse(line: line)
            blocks.append(block)
            if cursor != nil && line.range.contains(cursor!) {
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

    func replaceSelectedWithLink(_ string: String) -> Self? {
        if let selected = selected {
            let body = Block.templateLink(string)
            let next = self.base.replacingCharacters(
                in: selected.range,
                with: body
            )
            return .init(markup: next, cursor: self.cursor)
        }
        return nil
    }

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
            case .link:
                let text = block.stripped()
                let nsRange = NSRange(text.range, in: base)
                if let url = url(text) {
                    attributedString.addAttribute(
                        .link,
                        value: url,
                        range: nsRange
                    )
                }
            case let .heading(sub):
                let nsRange = NSRange(sub.range, in: base)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.appTextBold,
                    range: nsRange
                )
            default:
                break
            }
        }
        return attributedString
    }
}
