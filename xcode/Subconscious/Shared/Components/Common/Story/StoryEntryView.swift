//
//  StoryPlainView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// Show an excerpt of an entry in a feed
struct StoryEntryView: View {
    var story: StoryEntry
    var action: (Slashlink, String) -> Void

    var body: some View {
        Button(
            action: {
                action(
                    story.entry.address,
                    story.entry.excerpt
                )
            },
            label: {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Divider()
                    
                    HStack(alignment: .center, spacing: AppTheme.unit) {
                        BylineSmView(
                            pfp: .generated(story.entry.did),
                            slashlink: story.entry.address
                        )
                        
                        Spacer()
                        
                        Text(
                            NiceDateFormatter.shared.string(
                                from: story.entry.modified,
                                relativeTo: Date.now
                            )
                        )
                        .foregroundColor(.secondary)
                        .font(.caption)
                        
                    }
                    .padding(AppTheme.tightPadding)
                    .frame(height: AppTheme.unit * 12)
                    
                    Divider()
                    
                    ExcerptView(excerpt: story.entry.excerpt)
                        .padding(AppTheme.tightPadding)
                    
                    Divider()
                }
                .background(Color.background)
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
    }
}

struct StoryPlainView_Previews: PreviewProvider {
    static var previews: some View {
        StoryEntryView(
            story: StoryEntry(
                entry: EntryStub(
                    MemoEntry(
                        address: Slashlink("@here/meme")!,
                        contents: Memo(
                            contentType: ContentType.subtext.rawValue,
                            created: Date.now,
                            modified: Date.now.addingTimeInterval(TimeInterval(10000)),
                            fileExtension: ContentType.subtext.fileExtension,
                            additionalHeaders: [],
                            body: """
                            The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                            But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                            """
                        )
                    ),
                    did: Did.dummyData()
                )
            ),
            action: { _, _ in }
        )
    }
}
