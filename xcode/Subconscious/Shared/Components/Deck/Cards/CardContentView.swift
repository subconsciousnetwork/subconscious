//
//  CardContentView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct LikeButtonView: View {
    @State private var scale: CGFloat = 1.0
    var liked: Bool
    var action: () -> Void
    
    var body: some View {
        Button(
            action: {
                Task { await self.animateButton() }
                action()
            },
            label: {
                Image(
                    systemName: liked ? "heart.fill" : "heart"
                )
                .scaleEffect(scale)
            }
        )
    }
    
    func animateButton() async {
        // Perform the initial stretch animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
            self.scale = 1.5
        }
        
        // Wait for a brief moment
        try? await Task.sleep(nanoseconds: 100_000_000) // 100 milliseconds
        
        // Perform the bounce back animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
            self.scale = 1.0
        }
    }
}

struct CardContentView: View {
    @Environment (\.colorScheme) var colorScheme
    
    var entry: EntryStub
    var liked: Bool
    var related: Set<EntryStub>
    var notify: (EntryNotification) -> Void
    
    var highlight: Color {
        entry.highlightColor
    }
    
    var color: Color {
        entry.color
    }
    
    var body: some View {
        SubtextView(
            peer: entry.toPeer(),
            subtext: entry.excerpt,
            onLink: { link in notify(.requestLinkDetail(link)) }
        )
        // Opacity allows blendMode to show through
        .foregroundStyle(.primary.opacity(0.8))
        .accentColor(highlight)
        .frame(height: DeckTheme.cardContentSize.height, alignment: .topLeading)
        .truncateWithGradient(maxHeight: DeckTheme.cardContentSize.height)
        .padding(DeckTheme.cardPadding)
       
        Spacer()
        
        HStack {
            Text(
                entry.address.markup
            )
            .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: AppTheme.padding) {
                if !related.isEmpty {
                    HStack(spacing: AppTheme.unit2) {
                        Image(systemName: "link")
                        Text("\(related.count)")
                    }
                }
                
                HStack {
                    LikeButtonView(
                        liked: liked,
                        action: {
                            notify(
                                liked
                                   ? .unlike(entry.address)
                                   : .like(entry.address)
                            )
                        }
                    )
                }
            }
            .font(.callout)
        }
        .font(.caption)
        .foregroundStyle(highlight)
        .padding(DeckTheme.cardPadding)
    }
}
