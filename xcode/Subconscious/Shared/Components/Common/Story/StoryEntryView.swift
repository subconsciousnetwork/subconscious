//
//  StoryPlainView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

private struct StoryEntryUserDetailsView: View {
    var user: UserProfile
    
    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.unit2) {
            ProfilePic(pfp: user.pfp, size: .large)
            if let name = user.toNameVariant() {
                PetnameView(name: name, aliases: user.aliases)
            }
        }
    }
}

/// Show an excerpt of an entry in a feed
struct StoryEntryView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var story: StoryEntry
    var notify: (EntryNotification) -> Void
    
    var sharedNote: String {
        """
        \(story.entry.excerpt)
        
        \(story.entry.address)
        """
    }
    
    var author: UserProfile {
        story.author
    }
    
    var highlight: Color {
        story.entry.highlightColor
    }
    
    var color: Color {
        story.entry.color
    }
    
    var body: some View {
        Button(
            action: {
                notify(.tapped(story.entry))
            },
            label: {
                VStack(alignment: .leading, spacing: AppTheme.tightPadding) {
                        VStack(alignment: .leading, spacing: AppTheme.unit2) {
                            BylineSmView(
                                pfp: .generated(story.entry.did),
                                slashlink: story.entry.address,
                                highlight: highlight
                            )
                            
                            SubtextView(
                                peer: story.entry.toPeer(),
                                subtext: story.entry.excerpt,
                                onLink: { link in notify(.linkTapped(link)) }
                            )
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        }
                        .tint(highlight)
                        .truncateWithGradient(maxHeight: AppTheme.maxTranscludeHeight)
                }
                .contentShape(Rectangle())
            }
        )
        .contentShape(.interaction, RectangleCroppedTopRightCorner())
        .buttonStyle(
            EntryListRowButtonStyle(
                color: story.entry.color
            )
        )
        .contextMenu {
            ShareLink(item: sharedNote)
            
            if story.liked {
                Button(
                    action: {
                        notify(.unlike(story.entry.address))
                    },
                    label: {
                        Label(
                            "Remove from likes",
                            systemImage: "heart.slash"
                        )
                    }
                )
            } else {
                Button(
                    action: {
                        notify(.like(story.entry.address))
                    },
                    label: {
                        Label(
                            "Add to likes",
                            systemImage: "heart"
                        )
                    }
                )
            }
            
            Button(
                action: {
                    notify(.quote(story.entry.address))
                },
                label: {
                    Label(
                        "Quote in new note",
                        systemImage: "quote.opening"
                    )
                }
            )
        }
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
                ),
                author: UserProfile.dummyData(),
                liked: false
            ),
            notify: { _ in }
        )
    }
}
