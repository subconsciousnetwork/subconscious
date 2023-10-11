//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

struct ExcerptView: View {
    var excerpt: String
    var spacing: CGFloat = AppTheme.unit
    var excerptLines: [EnumeratedSequence<[String.SubSequence]>.Element] {
        Array(excerpt.split(separator: "\n").enumerated())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(excerptLines, id: \.offset) { idx, line in
                Text("\(String(line))")
                    .fontWeight(
                        idx == 0 && excerptLines.count > 1
                            ? .medium
                            : .regular
                    )
            }
        }
    }
}

struct TranscludeView: View {
    var entry: EntryStub
    var action: () -> Void
    
    var excerptLines: [EnumeratedSequence<[String.SubSequence]>.Element] {
        Array(entry.excerpt.split(separator: "\n").enumerated())
    }

    var body: some View {
        Button(
            action: action,
            label: {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    BylineSmView(
                        pfp: .generated(entry.did),
                        slashlink: entry.address
                    )
                    ExcerptView(excerpt: entry.excerpt)
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
                    excerpt: "Short.",
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("@gordon/loomings")!,
                    excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.",
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("/loomings")!,
                    excerpt: "Call me Ishmael. Some years ago- never mind how long precisely",
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:subconscious:local/loomings")!,
                    excerpt: """
                            Call me Ishmael.
                            Some years ago- never mind how long precisely
                            """,
                    modified: Date.now
                ),
                action: { }
            )
            TranscludeView(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:key:abc123/loomings")!,
                    excerpt: "Call me Ishmael. Some years ago- never mind how long precisely",
                    modified: Date.now
                ),
                action: { }
            )

        }
    }
}
