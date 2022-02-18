//
//  CollectionUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/17/22.
//

import Foundation

extension Collection {
    /// A safe bounds-checked array index lookup
    func get(index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
