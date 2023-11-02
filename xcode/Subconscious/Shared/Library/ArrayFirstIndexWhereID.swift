//
//  ArrayHelpers.swift
//  Subconscious
//
//  Created by Gordon Brander on 7/21/23.
//

import Foundation

extension Array where Element: Identifiable {
    func firstIndex(whereID id: Element.ID) -> Index? {
        firstIndex(where: { element in element.id == id })
    }
}
