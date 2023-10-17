//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

struct ExcerptView: View {
    var subtext: Subtext
    var spacing: CGFloat = AppTheme.unit

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("\(subtext.excerpt())")
        }
    }
}


struct TranscludeView: View {
    var entry: EntryStub
    var action: () -> Void
    
    var body: some View {
        Button(
            action: action,
            label: {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    BylineSmView(
                        pfp: .generated(entry.did),
                        slashlink: entry.address
                    )
                    
                    ExcerptView(subtext: entry.excerpt)
                }
            }
        )
        .buttonStyle(TranscludeButtonStyle())
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("/short")!,
                    excerpt: Subtext.truncate(text: "Short.", maxBlocks: 2),
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("@gordon/loomings")!,
                    excerpt: Subtext.truncate(
                        text: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.",
                        maxBlocks: 2
                    ),
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("/loomings")!,
                    excerpt: Subtext.truncate(
                        text: "Call me Ishmael. Some years ago- never mind how long precisely",
                        maxBlocks: 2
                    ),
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:subconscious:local/loomings")!,
                    excerpt: Subtext.truncate(
                        text: """
                              Call me Ishmael.
                              Some years ago- never mind how long precisely
                              """,
                        maxBlocks: 2
                    ),
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:key:abc123/loomings")!,
                    excerpt: Subtext.truncate(
                        text: "Call me Ishmael. Some years ago- never mind how long precisely",
                        maxBlocks: 2
                    ),
                    modified: Date.now
                ),
                action: { }
            )

        }
    }
}
