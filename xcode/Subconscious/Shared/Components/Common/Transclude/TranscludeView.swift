//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

struct TranscludeView: View {
    var entry: EntryStub
    var onLink: (EntryLink) -> Void
    
    @Environment (\.colorScheme) var colorScheme
    
    var highlight: Color {
        entry.highlightColor(
            colorScheme: colorScheme
        )
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
                        subtext: entry.excerpt,
                        onLink: { link in
                            let rebasedLink = link.rebaseIfNeeded(
                                peer: entry.toPeer()
                            )
                            onLink(rebasedLink)
                        }
                    )
                }
                .tint(highlight)
            }
        )
        .buttonStyle(
            TranscludeButtonStyle(
                color: entry.color(
                    colorScheme: colorScheme
                )
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
                    isTruncated: false,
                    modified: Date.now
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
                    isTruncated: false,
                    modified: Date.now
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
                    isTruncated: false,
                    modified: Date.now
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
                    isTruncated: false,
                    modified: Date.now
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
                    isTruncated: false,
                    modified: Date.now
                ),
                onLink: { _ in }
            )

        }
    }
}
