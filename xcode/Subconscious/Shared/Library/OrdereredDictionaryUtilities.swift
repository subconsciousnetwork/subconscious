//
//  OrdereredDictionaryUtilities.swift
//  OrdereredDictionaryUtilities
//
//  Created by Gordon Brander on 9/1/21.
//

import OrderedCollections

extension OrderedDictionary {
    /// Inserts a key-value tuple at the specified index of an `OrderedDictionary`.
    /// If Key conflicts with an existing key, this new value/index overwrites the old value.
    /// Returns a new `OrderedDictionary`.
    func inserting(
        key: OrderedDictionary.Key,
        value: OrderedDictionary.Value,
        at index: OrderedDictionary.Index
    ) -> OrderedDictionary {
        var pairs = Array(self.elements)
        pairs.insert((key, value), at: index)
        return OrderedDictionary(pairs, uniquingKeysWith: { _, last in
            last
        })
    }

    mutating func removeKeys(keys: [OrderedDictionary.Key]) {
        for key in keys {
            self.removeValue(forKey: key)
        }
    }

    /// Get offset index, clamped between start and end indexes.
    func index(
        _ index: OrderedDictionary.Index,
        offsetBy offset: Int
    ) -> OrderedDictionary.Index? {
        let i = index + offset
        if i < self.keys.startIndex || i > self.keys.endIndex {
            return nil
        } else {
            return i
        }
    }

    func key(before key: OrderedDictionary.Key) -> OrderedDictionary.Key? {
        if
            let index = self.index(forKey: key),
            let prevIndex = self.index(index, offsetBy: -1)
        {
            return keys[prevIndex]
        }
        return nil
    }

    func key(after key: OrderedDictionary.Key) -> OrderedDictionary.Key? {
        if
            let index = self.index(forKey: key),
            let nextIndex = self.index(index, offsetBy: 1)
        {
            return keys[nextIndex]
        }
        return nil
    }
}
