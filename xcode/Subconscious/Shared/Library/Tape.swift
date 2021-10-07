//
//  Tape.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/6/21.
//

import Foundation

/// An set of advanceable indices into a collection
/// Useful for for parsing.
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

    init(_ collection: T) {
        self.collection = collection
        let start = collection.startIndex
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

    /// Take current subsequence and advance startIndex to end of subsequence.
    mutating func snip() -> T.SubSequence {
        let subsequence = self.subsequence
        self.setStart()
        return subsequence
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

    /// Consume tape until you encounter a flag subsequence, or until tape is exhausted.
    /// Return subsequence up until flag, but not including flag.
    mutating func consumeUntil(_ flag: T.SubSequence) -> T.SubSequence {
        self.setStart()
        while !isExhausted() {
            if peek(next: flag.count) == flag {
                return self.snip()
            }
            self.advance()
        }
        return self.snip()
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
