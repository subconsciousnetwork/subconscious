//
//  CollectionUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/17/22.
//

import Foundation

extension Collection {
    /// A safe bounds-checked array index lookup
    func get(_ index: Index) -> Element? {
        guard index >= startIndex && index < endIndex else {
            return nil
        }
        return self[index]
    }
}

extension Array {
    /// Unique elements in an array, returning a new array.
    /// Function `with` reads each element, producing an identifying key.
    /// The first element for each key is kept.
    func uniquing<T>(with read: (Element) -> T) -> [Element]
    where T: Hashable
    {
        var unique: [Element] = []
        var seen: Set<T> = Set()
        for element in self {
            let key = read(element)
            if !seen.contains(key) {
                unique.append(element)
            }
            seen.insert(key)
        }
        return unique
    }
}
