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
    case prompt(
        message: String,
        entry: EntryStub,
        author: UserProfile,
        backlinks: [EntryStub]
    )
}

struct CardModel: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var card: CardType
    
    var author: UserProfile? {
        switch card {
        case let .entry(_, author, _):
            return author
        case let .prompt(_, _, author, _):
            return author
        default:
            return nil
        }
    }
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
        switch card {
        case let .entry(entry, _, _):
            return entry
        case let .prompt(_, entry, _, _):
            return entry
        default:
            return nil
        }
    }
}
