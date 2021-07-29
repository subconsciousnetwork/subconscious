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

extension Sequence {
    /// Subtract the elements of an array from this array, returning a new array.
    public func subtracting(
        _ array: Array<Iterator.Element>
    ) -> [Iterator.Element]
    where Iterator.Element: Hashable
    {
        let set = Set(array)
        return filter({ item in !set.contains(item) })
    }

    /// Subtract the elements of an array from this array, returning a new array.
    public func subtracting<T>(
        _ array: Array<Iterator.Element>,
        with read: (Iterator.Element) -> T
    ) -> [Iterator.Element]
    where T: Hashable {
        let set = Set(array.map(read))
        return filter({ item in !set.contains(read(item)) })
    }
}

extension Array {
    public func get(_ index: Array.Index) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        } else {
            return nil
        }
    }

    /// Append two arrays, returning a new array.
    /// Chainable method version of "+" operator.
    public func appending(contentsOf array: [Element]) -> [Element] {
        return self + array
    }
}
