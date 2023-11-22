//
//  CardModel.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 22/11/2023.
//

import Foundation


enum CardType: Equatable, Hashable {
    case entry(
        entry: EntryStub,
        author: UserProfile,
        backlinks: [EntryStub]
    )
    case action(String)
}

struct CardModel: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var card: CardType
}

extension CardModel {
    init(
        entry: EntryStub,
        user: UserProfile,
        backlinks: [EntryStub]
    ) {
        self.init(
            card: .entry(
                entry: entry,
                author: user,
                backlinks: backlinks
            )
        )
    }
    
    var entry: EntryStub? {
        guard case let .entry(entry, _, _) = card else {
            return nil
        }
        
        return entry
    }
}
