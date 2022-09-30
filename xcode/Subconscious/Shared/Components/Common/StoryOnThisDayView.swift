//
//  StoryOnThisDayView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/9/2022.
//

import Foundation
import SwiftUI

/// A story is a single update within the FeedView
struct StoryOnThisDayView: View {
    var story: StoryOnThisDay
    var action: (EntryLink, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.unit) {
                Text("@bfollington")
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
                Text("On this day \(story.timespan) ago:")
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

struct StoryOnThisDayView_Previews: PreviewProvider {
    static var previews: some View {
        StoryOnThisDayView(
            story: StoryOnThisDay(
                entry: EntryStub(
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
                timespan: "6mo"
            ),
            action: { link, fallback in }
        )
    }
}
