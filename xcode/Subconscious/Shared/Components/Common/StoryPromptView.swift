//
//  StoryPromptView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import SwiftUI

/// A story is a single update within the FeedView
struct StoryPromptView: View {
    var story: StoryPrompt
    var action: (EntryLink, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.unit) {
                Text("@cdata")
                Text("at")
                    .foregroundColor(Color.secondary)
                Text(story.entry.modified.formatted())
                    .foregroundColor(Color.secondary)
                Spacer()
            }
            .font(Font(UIFont.appTextSmall))
            .padding()
            .frame(height: AppTheme.unit * 11)
            Divider()
            VStack(alignment: .leading, spacing: AppTheme.unit4) {
                Text(story.prompt)
                Button(
                    action: {
                        action(
                            story.entry.link,
                            story.entry.link.linkableTitle
                        )
                    },
                    label: {
                        TranscludeView(entry: story.entry)
                    }
                )
                .buttonStyle(.plain)
            }
            .padding()
            Divider()
            HStack {
                Button(
                    action: {
                        action(
                            story.entry.link,
                            story.entry.link.linkableTitle
                        )
                    },
                    label: {
                        Text("Open")
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

struct StoryPromptView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPromptView(
            story: StoryPrompt(
                entry: EntryStub(
                    SubtextEntry(
                        slug: Slug("meme")!,
                        contents: Memo(
                            contentType: .subtext,
                            created: Date.now,
                            modified: Date.now,
                            title: "Meme",
                            body: Subtext(
                                markup: """
                                The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                                But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                                """
                            )
                        )
                    )
                ),
                prompt: "Can I invert this?"
            ),
            action: { link, fallback in }
        )
    }
}
