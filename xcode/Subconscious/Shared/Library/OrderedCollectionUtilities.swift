//
//  OrderedCollectionUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/7/22.
//

import Foundation
import OrderedCollections

extension OrderedDictionary {
    /// Set a value value at key, only if a value does not already
    /// exist at key.
    /// - Returns the now value at key
    @discardableResult mutating func setDefault(
        _ defaultValue: Value,
        forKey key: Key
    ) -> Value {
        guard let value = self[key] else {
            self[key] = defaultValue
            return defaultValue
        }
        return value
    }
}
