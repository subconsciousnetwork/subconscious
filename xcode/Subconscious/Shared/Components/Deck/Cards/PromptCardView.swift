//
//  PromptCardView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct PromptCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var message: String
    var entry: EntryStub
    var related: Set<EntryStub>
    var onLink: (EntryLink) -> Void
    
    var background: Color {
        entry.color(colorScheme: colorScheme)
    }
    
    var highlight: Color {
        entry.highlightColor(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "sparkles")
                
                Text(message)
                
                Spacer()
            }
            .padding(DeckTheme.cardPadding)
            .foregroundStyle(highlight)
            .font(.subheadline)
            .background(
                DeckTheme.cardHeaderTint.blendMode(
                    .plusLighter
                )
            )
            
            Divider()
            
            CardContentView(
                entry: entry,
                related: related,
                onLink: onLink
            )
        }
        .allowsHitTesting(false)
        .background(background)
        .cornerRadius(DeckTheme.cornerRadius)
    }
}

