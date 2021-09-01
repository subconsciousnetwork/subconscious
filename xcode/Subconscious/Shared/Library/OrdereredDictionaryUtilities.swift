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
}
