//
//  StoryComboView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/9/2022.
//

import SwiftUI

/// A story is a single update within the FeedView
struct StoryComboView: View {
    var story: StoryCombo
    var action: (MemoAddress, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.unit) {
                Text("@bfollington")
                Text("at")
                    .foregroundColor(Color.secondary)
                Text(story.entryA.modified.formatted())
                    .foregroundColor(Color.secondary)
                Spacer()
            }
            .font(.caption)
            .padding()
            .frame(height: AppTheme.unit * 11)
            Divider()
            VStack(alignment: .leading, spacing: AppTheme.unit4) {
                Text(story.prompt)
                
                Button(
                    action: {
                        action(story.entryA.address, story.entryA.title)
                    },
                    label: {
                        TranscludeView(
                            pfp: Image("pfp-dog"),
                            petname: "@doge",
                            slashlink: story.entryA.address.slug.toSlashlink(),
                            title: story.entryA.title,
                            excerpt: story.entryA.excerpt
                        )
                    }
                )
                .buttonStyle(.plain)
                
                Button(
                    action: {
                        action(story.entryB.address, story.entryB.title)
                    },
                    label: {
                        TranscludeView(
                            pfp: Image("pfp-dog"),
                            petname: "@doge",
                            slashlink: story.entryB.address.slug.toSlashlink(),
                            title: story.entryB.title,
                            excerpt: story.entryB.excerpt
                        )
                    }
                )
                .buttonStyle(.plain)
            }
            .padding()
            Divider()
            HStack {
                Button(
                    action: {
                        guard let entry = MemoEntry(story) else {
                            return
                        }
                        let link = EntryLink(entry)
                        self.action(entry.address, entry.contents.title)
                    },
                    label: {
                        Text("Create")
                    }
                )
                Spacer()
            }
            .padding()
            .frame(height: AppTheme.unit * 15)
            ThickDividerView()
        }
    }
}

struct StoryComboView_Previews: PreviewProvider {
    static var previews: some View {
        StoryComboView(
            story: StoryCombo(
                prompt: "How are these similar?",
                entryA: EntryStub(
                    MemoEntry(
                        address: Slug("meme")!.toLocalMemoAddress(),
                        contents: Memo(
                            contentType: ContentType.subtext.rawValue,
                            created: Date.now,
                            modified: Date.now,
                            title: "Meme",
                            fileExtension: ContentType.subtext.fileExtension,
                            additionalHeaders: [],
                            body: """
                            The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                            But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                            """
                        )
                    )
                ),
                entryB: EntryStub(
                    MemoEntry(
                        address: Slug("meme")!.toLocalMemoAddress(),
                        contents: Memo(
                            contentType: ContentType.subtext.rawValue,
                            created: Date.now,
                            modified: Date.now,
                            title: "Meme",
                            fileExtension: ContentType.subtext.fileExtension,
                            additionalHeaders: [],
                            body: """
                            Title: Meme
                            Modified: 2022-08-23
                            
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
