//
//  ArrayChanges.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 11/20/23.
//

import Foundation

enum ElementChange<Element>: Hashable
where Element: Hashable & Identifiable
{
    typealias Offset = Int
    case added(offset: Offset, element: Element)
    case updated(offset: Offset, element: Element)
    
    var id: Element.ID {
        switch self {
        case .added(_, let element):
            return element.id
        case .updated(_, let element):
            return element.id
        }
    }
}

extension Array where Element: Identifiable & Hashable {
    /// Given an array of identifiable items in `from`, calculates which items
    /// in `self` were added and updated in comparison to `from`.
    ///
    /// Complexity is `O(n+m)` where `n` is this collection, and `m` is the
    /// other collection.
    func changes(from other: [Element]) -> Set<ElementChange<Element>> {
        let index = Dictionary<Element.ID, Element>(
            uniqueKeysWithValues: other.map({ item in
                return (item.id, item)
            })
        )
        
        var changed: Set<ElementChange<Element>> = []
        for (i, element) in self.enumerated() {
            if let prev = index[element.id] {
                if (prev != element) {
                    changed.insert(
                        .updated(offset: i, element: element)
                    )
                }
            } else {
                changed.insert(
                    .added(offset: i, element: element)
                )
            }
        }
        
        return changed
    }
}
