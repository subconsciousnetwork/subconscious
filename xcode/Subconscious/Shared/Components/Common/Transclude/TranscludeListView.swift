//
//  TranscludeListView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/11/23.
//

import SwiftUI

struct TranscludeListView: View {
    var entries: [EntryStub]
    var onLink: (EntryLink) -> Void
    var backgroundMode: TranscludeBackgroundMode = .colored
    
    @Environment (\.colorScheme) var colorScheme
    
    var body: some View {
        LazyVStack(spacing: AppTheme.unit2) {
            ForEach(entries, id: \.self) { entry in
                VStack {
                    TranscludeView(
                        entry: entry,
                        onLink: onLink,
                        backgroundMode: backgroundMode
                    )
//                    .shadow(
//                        color: DeckTheme.cardShadow.opacity(0.08),
//                        radius: 1.5,
//                        x: 0,
//                        y: 1.5
//                    )
                }
                .tint(
                    entry.headers.themeColor?.toHighlightColor()
                )
            }
        }
    }
}

struct TranscludeListView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeListView(
            entries: [
                EntryStub(
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
            ],
            onLink: { _ in }
        )
    }
}
