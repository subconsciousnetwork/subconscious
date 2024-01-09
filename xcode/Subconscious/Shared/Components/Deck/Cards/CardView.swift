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
    
    var entry: CardModel
    var onLink: (EntryLink) -> Void
    
    var color: Color {
        switch entry.card {
        case let .entry(entry, _, _):
            return entry.color(colorScheme: colorScheme)
        case let .prompt(_, entry, _, _):
            return entry.color(colorScheme: colorScheme)
        default:
            return .secondary
        }
    }
    
    var highlight: Color {
        switch entry.card {
        case let .entry(entry, _, _):
            return entry.highlightColor(colorScheme: colorScheme)
        case let .prompt(_, entry, _, _):
            return entry.highlightColor(colorScheme: colorScheme)
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
            switch entry.card {
            case let .entry(entry, _, related):
                EntryCardView(
                    entry: entry,
                    related: related,
                    onLink: onLink
                )
            case let .prompt(message, entry, _, related):
                PromptCardView(
                    message: message,
                    entry: entry,
                    related: related,
                    onLink: onLink
                )
                
            case let .action(message):
                ActionCardView(message: message)
            }
        }
        
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(entry: CardModel(
            card: .prompt(
                message: "Hello",
                entry: EntryStub.dummyData(),
                author: UserProfile.dummyData(),
                related: []
            )
        ),
                 onLink: {
            _ in
        })
    }
}
