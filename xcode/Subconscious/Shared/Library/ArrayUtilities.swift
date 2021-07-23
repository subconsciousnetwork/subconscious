//
//  ArrayUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/13/21.
//  Array and Sequence extensions and utilities.

import Foundation

extension Sequence where Iterator.Element: Hashable {
    /// Filter unique elements, as determined by hashable.
    /// First element wins.
    public func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter({ item in seen.insert(item).inserted })
    }

    /// Construct dictionary from array, using key function
    public func toDictionary<Key: Hashable>(
        key: (Iterator.Element) -> Key
    ) -> [Key:Iterator.Element] {
        var dict: [Key:Iterator.Element] = [:]
        for element in self {
            dict[key(element)] = element
        }
        return dict
    }
}

extension Array {
    /// Append two arrays, returning a new array.
    /// Chainable method version of "+" operator.
    public func appending(contentsOf array: [Element]) -> [Element] {
        return self + array
    }
}
