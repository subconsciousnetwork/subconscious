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
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter({ item in seen.insert(item).inserted })
    }
}
