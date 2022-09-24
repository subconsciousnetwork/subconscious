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
    var action: (EntryLink, String) -> Void

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
            .font(Font(UIFont.appTextSmall))
            .padding()
            .frame(height: AppTheme.unit * 11)
            Divider()
            VStack(alignment: .leading, spacing: AppTheme.unit4) {
                Button(
                    action: {
                        action(story.entryA.link, story.entryA.linkableTitle)
                    },
                    label: {
                        TranscludeView(entry: story.entryA)
                    }
                )
                .buttonStyle(.plain)
                
                Button(
                    action: {
                        action(story.entryB.link, story.entryB.linkableTitle)
                    },
                    label: {
                        TranscludeView(entry: story.entryB)
                    }
                )
                .buttonStyle(.plain)
            }
            .padding()
            Divider()
            HStack {
                // TODO: make this actually do something
                // pop open a new note with the other two notes already transcluded in it
                Button(
                    action: {
                        action(story.entryA.link, story.entryA.linkableTitle)
                    },
                    label: {
                        Text("Synthesize")
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
                entryA: EntryStub(
                    SubtextFile(
                        slug: Slug("meme")!,
                        content: """
                        Title: Meme
                        Modified: 2022-08-23
                        
                        The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                        But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                        """
                    )
                ),
                entryB: EntryStub(
                    SubtextFile(
                        slug: Slug("meme")!,
                        content: """
                        Title: Meme
                        Modified: 2022-08-23
                        
                        The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                        But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                        """
                    )
                )
            ),
            action: { link, fallback in }
        )
    }
}
