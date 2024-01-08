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
        SubtextView(
            peer: entry.toPeer(),
            subtext: entry.excerpt,
            onLink: onLink
        )
        // Opacity allows blendMode to show through
        .foregroundStyle(.primary.opacity(0.8))
        .accentColor(highlight)
        .frame(height: DeckTheme.cardContentSize.height, alignment: .topLeading)
        .padding(DeckTheme.cardPadding)
        .clipped()
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            stops: [
                                Gradient.Stop(
                                    color: color.opacity(0),
                                    location: 0
                                ),
                                Gradient.Stop(
                                    color: color,
                                    location: 0.8
                                )
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 44, alignment: .bottom),
            alignment: .bottom
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
