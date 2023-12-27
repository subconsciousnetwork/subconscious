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
        switch entry.card {
        case let .entry(entry, _, backlinks):
            EntryCardView(
                entry: entry,
                backlinks: backlinks,
                onLink: onLink
            )
        case let .prompt(message, entry, _, backlinks):
            PromptCardView(
                message: message,
                entry: entry,
                backlinks: backlinks,
                onLink: onLink
            )
        case let .action(message):
            ActionCardView(message: message)
        }
    }
}
