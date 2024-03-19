//
//  CardView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct CardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var card: CardModel
    var notify: (EntryNotification) -> Void
    
    var color: Color {
        switch card.card {
        case let .entry(entry, _, _):
            return entry.color
        case let .prompt(_, entry, _, _):
            return entry.color
        default:
            return .secondary
        }
    }
    
    var highlight: Color {
        switch card.card {
        case let .entry(entry, _, _):
            return entry.highlightColor
        case let .prompt(_, entry, _, _):
            return entry.highlightColor
        default:
            return .secondary
        }
    }
    
    var blendMode: BlendMode {
        colorScheme == .dark
           ? .plusLighter
           : .plusDarker
    }
    
    var body: some View {
        VStack {
            switch card.card {
            case let .entry(entry, _, related):
                EntryCardView(
                    entry: entry,
                    liked: self.card.liked,
                    related: related,
                    notify: notify
                )
            case let .prompt(message, entry, _, related):
                PromptCardView(
                    message: message,
                    entry: entry,
                    liked: self.card.liked,
                    related: related,
                    notify: notify
                )
            case let .reward(message):
                RewardCardView(message: message)
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(
            card: CardModel(
                card: .prompt(
                    message: "Hello",
                    entry: EntryStub.dummyData(),
                    author: UserProfile.dummyData(),
                    related: []
                ),
                liked: false
            ),
            notify: { _ in }
        )
    }
}
