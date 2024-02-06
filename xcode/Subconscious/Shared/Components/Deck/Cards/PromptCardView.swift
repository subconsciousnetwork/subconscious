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
    var onQuote: (Slashlink) -> Void
    
    var background: Color {
        entry.color
    }
    
    var highlight: Color {
        entry.highlightColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "sparkles")
                
                // By default this view refused to wrap onto a second line
                // Resolved via https://stackoverflow.com/a/59277022
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
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
        .contextMenu {
            ShareLink(item: entry.sharedText)
            
            Button(
                action: {
                    onQuote(entry.address)
                },
                label: {
                    Label(
                        "Quote in new note",
                        systemImage: "quote.opening"
                    )
                }
            )
        }
    }
}

