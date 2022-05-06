//
//  Tape.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/25/21.
//

import Foundation

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

    var isAtBeginning: Bool {
        self.startIndex == self.collection.startIndex
    }

    func isExhausted() -> Bool {
        return self.currentIndex >= self.collection.endIndex
    }

    /// Sets the start of the current range to the current index.
    /// Generally called at the beginning of parsing a token, to mark the beginning of the token range.
    mutating func start() {
        startIndex = currentIndex
    }

    /// Get current subsequence, and advance start index to current index.
    /// Conceptually like snipping off a piece of tape so that you have the piece up until the cut,
    /// and the cut becomes the new start of the tape.
    mutating func cut() -> T.SubSequence {
        let subsequence = collection[startIndex..<currentIndex]
        startIndex = currentIndex
        return subsequence
    }
    
    mutating func save() {
        savedIndex = currentIndex
    }

    mutating func backtrack() {
        startIndex = savedIndex
        currentIndex = savedIndex
    }

    /// Move tape index forward by one
    mutating func advance() {
        _ = self.collection.formIndex(
            &self.currentIndex,
            offsetBy: 1,
            limitedBy: collection.endIndex
        )
    }

    /// Move forward one element.
    /// Returns `Element` at the `currentIndex` before advancing.
    mutating func consume() -> T.Element {
        let element = collection[currentIndex]
        self.advance()
        return element
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

    /// Peek forward at next `Collection.Item` and consume if it matches
    /// predicate function
    mutating func consumeMatch(where predicate: (T.Element) -> Bool) -> Bool {
        if predicate(collection[currentIndex]) {
            self.advance()
            return true
        }
        return false
    }

    /// Get an item offset by `offset` from the `currentIndex`.
    /// Returns a `Collection.Element`, or nil if `offset` is invalid.
    func peek(offset: Int = 0) -> T.Element? {
        if
            let i = collection.index(
                currentIndex,
                offsetBy: offset,
                limitedBy: collection.endIndex
            )
        {
            if i < collection.endIndex {
                return collection[i]
            }
        }
        return nil
    }

    /// Peek forward by `offset`, returning a subsequence
    /// from `position` through `offset`.
    /// If offset would be out of range, returns nil.
    func peek(next offset: Int) -> T.SubSequence? {
        if let endIndex = collection.index(
            currentIndex,
            offsetBy: offset,
            limitedBy: collection.endIndex
        ) {
            return collection[currentIndex..<endIndex]
        } else {
            return nil
        }
    }
}

struct Tape2 {
    private(set) var savedIndex: Substring.Index
    private(set) var currentIndex: Substring.Index
    var rest: Substring

    init(_ rest: Substring) {
        self.rest = rest
        self.currentIndex = rest.startIndex
        self.savedIndex = rest.startIndex
    }

    var isAtBeginning: Bool {
        self.currentIndex == self.rest.base.startIndex
    }

    func isExhausted() -> Bool {
        return self.currentIndex >= self.rest.endIndex
    }

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

    /// Peek forward at next `Collection.Item` and consume if it matches
    /// predicate function
    mutating func consumeMatch(where predicate: (Character) -> Bool) -> Bool {
        if predicate(rest[currentIndex]) {
            self.advance()
            return true
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
