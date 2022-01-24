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

    /// Get current subsequence
    var subsequence: T.SubSequence {
        collection[startIndex..<currentIndex]
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

    /// Move forward one element
    @discardableResult mutating func consume() -> T.SubSequence {
        let subsequence = collection[currentIndex...currentIndex]
        _ = self.collection.formIndex(
            &self.currentIndex,
            offsetBy: 1,
            limitedBy: collection.endIndex
        )
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

    /// Peek forward at next `Collection.Item` and consume if it matches
    /// predicate function
    mutating func consumeMatch(where predicate: (T.Element) -> Bool) -> Bool {
        if predicate(collection[currentIndex]) {
            self.consume()
            return true
        }
        return false
    }

    /// Get a single-item SubSequence offset by `offset` of the `currentStartIndex`.
    /// Returns a single-item SubSequence, or nil if `offset` is invalid.
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
    /// or from `position` through `endIndex`, whichever is smaller.
    func peek(next offset: Int) -> T.SubSequence {
        if let endIndex = collection.index(
            currentIndex,
            offsetBy: offset,
            limitedBy: collection.endIndex
        ) {
            return collection[currentIndex..<endIndex]
        } else {
            return collection[currentIndex..<collection.endIndex]
        }
    }
}
