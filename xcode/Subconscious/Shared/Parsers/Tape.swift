//
//  Tape.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/25/21.
//

import Foundation

struct Tape {
    /// Saved index, used for backtracking
    private(set) var savedIndex: Substring.Index
    /// Current index, used for slicing substrings off of
    /// the beginning of the tape.
    private(set) var currentIndex: Substring.Index
    /// The original substring
    private(set) var base: Substring
    /// The "rest" of the substring at the current state of the parser
    private(set) var rest: Substring

    init(_ base: Substring) {
        self.base = base
        self.rest = base
        self.currentIndex = rest.startIndex
        self.savedIndex = rest.startIndex
    }

    /// Is tape at beginning? Equivalient to `^` in regex.
    var isAtBeginning: Bool {
        self.currentIndex == self.base.startIndex
    }

    /// Is tape exhausted (at end)?
    func isExhausted() -> Bool {
        return self.currentIndex >= self.rest.endIndex
    }

    /// Get an index offset by some amount
    private func offset(by offset: Int) -> Substring.Index? {
        self.rest.index(
            self.currentIndex,
            offsetBy: offset,
            limitedBy: rest.endIndex
        )
    }

    /// Sets the start of the current range to the current index.
    /// Generally called at the beginning of parsing a token, to mark the beginning of the token range.
    mutating func start() {
        self.rest = rest.suffix(from: currentIndex)
    }

    /// Get current subsequence, and advance start index to current index.
    /// Conceptually like snipping off a piece of tape so that you have the piece up until the cut,
    /// and the cut becomes the new start of the tape.
    mutating func cut() -> Substring {
        let subsequence = rest.prefix(upTo: currentIndex)
        self.rest = rest.suffix(from: currentIndex)
        return subsequence
    }

    mutating func save() {
        savedIndex = currentIndex
    }

    mutating func backtrack() {
        currentIndex = savedIndex
        self.rest = self.base.suffix(from: savedIndex)
    }

    /// Move tape index forward by one
    mutating func advance() {
        self.currentIndex = self.offset(by: 1) ?? rest.endIndex
    }

    /// Move forward one element.
    /// Returns `Element` at the `currentIndex` before advancing.
    mutating func consume() -> Character {
        let element = rest[currentIndex]
        self.advance()
        return element
    }

    /// Peek forward, and consume if match
    mutating func consumeMatch(_ subsequence: Substring) -> Bool {
        if let endIndex = offset(by: subsequence.count) {
            if rest[currentIndex..<endIndex] == subsequence {
                self.currentIndex = endIndex
                return true
            }
        }
        return false
    }

    /// Get an item offset by `offset` from the `currentIndex`.
    /// Returns a `Collection.Element`, or nil if `offset` is invalid.
    func peek(offset: Int = 0) -> Character? {
        if let i = self.offset(by: offset) {
            if i < rest.endIndex {
                return rest[i]
            }
        }
        return nil
    }

    /// Peek forward by `offset`, returning a subsequence
    /// from `position` through `offset`.
    /// If offset would be out of range, returns nil.
    func peek(next offset: Int) -> Substring? {
        if let endIndex = self.offset(by: offset) {
            return rest[currentIndex..<endIndex]
        } else {
            return nil
        }
    }
}
