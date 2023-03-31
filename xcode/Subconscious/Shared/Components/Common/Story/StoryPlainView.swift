//
//  StoryPlainView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// A story is a single update within the FeedView
struct StoryPlainView: View {
    var story: StoryPlain
    var action: (MemoAddress, String) -> Void

    var body: some View {
        Button(
            action: {
                action(
                    story.entry.address,
                    story.entry.excerpt
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: AppTheme.unit) {
                    BylineSmView(
                        pfp: Image("pfp-dog"),
                        slashlink: story.entry.address.toSlashlink()
                    )
                    Group {
                        Text("at")
                            .foregroundColor(Color.secondary)
                        Text(story.entry.modified.formatted())
                            .foregroundColor(Color.secondary)
                    }
                    .font(.caption)
                    Spacer()
                }
                .padding()
                .frame(height: AppTheme.unit * 11)
                Divider()
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    Text(story.entry.excerpt)
                    
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
        .background(Color.background)
    }
}

struct StoryPlainView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPlainView(
            story: StoryPlain(
                entry: EntryStub(
                    MemoEntry(
                        address: MemoAddress.public(
                            Slashlink("@here/meme")!
                        ),
                        contents: Memo(
                            contentType: ContentType.subtext.rawValue,
                            created: Date.now,
                            modified: Date.now,
                            fileExtension: ContentType.subtext.fileExtension,
                            additionalHeaders: [],
                            body: """
                            The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                            But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                            """
                        )
                    )
                )
            ),
            action: { link, fallback in }
        )
    }
}


import Foundation