//
//  CardContentView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct CardContentView: View {
    @Environment (\.colorScheme) var colorScheme
    
    var entry: EntryStub
    var backlinks: [EntryStub]
    var onLink: (EntryLink) -> Void
    
    var highlight: Color {
        entry.highlightColor(colorScheme: colorScheme)
    }
    
    var color: Color {
        entry.color(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack {
            SubtextView(
                peer: entry.toPeer(),
                subtext: entry.excerpt,
                onLink: onLink
            )
            Spacer()
        }
        // Opacity allows blendMode to show through
        .foregroundStyle(.primary.opacity(0.8))
        .accentColor(highlight)
        .padding(DeckTheme.cardPadding)
        .frame(maxHeight: DeckTheme.cardSize.height, alignment: .leading)
        .overlay(
            GeometryReader { geometry in
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, color]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 64)
                    .offset(y: geometry.size.height - 64) // Adjusting the y offset to position at the bottom
            }
        )
        
        Spacer()
        
        HStack {
            Text(
                entry.address.markup
            )
            .lineLimit(1)
            
            if !backlinks.isEmpty {
                Spacer()
                
                HStack {
                    Image(systemName: "link")
                    Text("\(backlinks.count)")
                }
            }
        }
        .font(.caption)
        .foregroundStyle(highlight)
        .padding(DeckTheme.cardPadding)
    }
}
