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
    var liked: Bool
    var related: Set<EntryStub>
    var notify: (EntryNotification) -> Void
    
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
                liked: liked,
                related: related,
                notify: notify
            )
        }
//        .allowsHitTesting(false)
        .background(background)
        .cornerRadius(DeckTheme.cornerRadius)
        .contextMenu {
            ShareLink(item: entry.sharedText)
            
            if liked {
                Button(
                    action: {
                        notify(.unlike(entry.address))
                    },
                    label: {
                        Label(
                            "Unlike",
                            systemImage: "heart.slash"
                        )
                    }
                )
            } else {
                Button(
                    action: {
                        notify(.like(entry.address))
                    },
                    label: {
                        Label(
                            "Like",
                            systemImage: "heart"
                        )
                    }
                )
            }
            
            Button(
                action: {
                    notify(.quote(entry.address))
                },
                label: {
                    Label(
                        "Quote",
                        systemImage: "quote.opening"
                    )
                }
            )
        }
    }
}

struct PromptCardView_Previews: PreviewProvider {
    static var previews: some View {
        PromptCardView(
            message: "Henlo world!",
            entry: EntryStub.dummyData(),
            liked: true,
            related: [EntryStub.dummyData()],
            notify: { _ in }
        )
    }
}
