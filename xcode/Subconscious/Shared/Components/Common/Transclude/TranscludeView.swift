//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

enum TranscludeBackgroundMode {
    case colored
    case plain
}

struct TranscludeView: View {
    var entry: EntryStub
    var onLink: (EntryLink) -> Void
    var backgroundMode: TranscludeBackgroundMode = .colored
    
    @Environment (\.colorScheme) var colorScheme
    
    var highlight: Color {
        if backgroundMode == .plain {
            return .accentColor
        }
        return entry.highlightColor(
            colorScheme: colorScheme
        )
    }
    
    var color: Color {
        backgroundMode == .colored 
            ? entry.color(
                colorScheme: colorScheme
            ) 
            : .secondaryBackground.opacity(0.1)
        
    }
    
    var body: some View {
        Button(
            action: {
                onLink(EntryLink(entry))
            },
            label: {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    BylineSmView(
                        pfp: .generated(entry.did),
                        slashlink: entry.address,
                        highlight: highlight
                    )
                    
                    SubtextView(
                        peer: entry.toPeer(),
                        subtext: entry.excerpt,
                        onLink: onLink
                    )
                }
                .tint(backgroundMode == .colored ? highlight : nil)
                .truncateWithGradient(color: color, maxHeight: AppTheme.maxTranscludeHeight)
            }
        )
        .buttonStyle(
            TranscludeButtonStyle(
                color: color
            )
        )
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("/short")!,
                    excerpt: Subtext(markup: "Short."),
                    headers: .emptySubtext
                ),
                onLink: { _ in }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("@gordon/loomings")!,
                    excerpt: Subtext(
                        markup: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation."
                    ),
                    headers: .emptySubtext
                ),
                onLink: { _ in }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("/loomings")!,
                    excerpt: Subtext(
                        markup: "Call me Ishmael. Some years ago- never mind how long precisely"
                    ),
                    headers: .emptySubtext
                ),
                onLink: { _ in }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:subconscious:local/loomings")!,
                    excerpt: Subtext(
                        markup: """
                              Call me Ishmael.
                              Some years ago- never mind how long precisely
                              """
                    ),
                    headers: .emptySubtext
                ),
                onLink: { _ in }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:key:abc123/loomings")!,
                    excerpt: Subtext(
                        markup: "Call me Ishmael. Some years ago- never mind how long precisely"
                    ),
                    headers: .emptySubtext
                ),
                onLink: { _ in }
            )

        }
    }
}
