//
//  BidirectionalCollectionDifferenceUsingIdentities.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/20/23.
//

import Foundation

extension BidirectionalCollection {
    func differenceByID<C>(
        from other: C
    ) -> CollectionDifference<Self.Element.ID>
    where
        Self.Element: Identifiable,
        Self.Element.ID: Hashable,
        C: BidirectionalCollection,
        Self.Element == C.Element
    {
        let otherIds = other.map(\.id)
        let selfIds = self.map(\.id)
        return selfIds.difference(from: otherIds).inferringMoves()
    }
}
