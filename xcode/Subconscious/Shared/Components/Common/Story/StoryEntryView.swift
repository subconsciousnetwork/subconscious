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
    var story: StoryEntry
    var onRequestDetail: (Slashlink, String) -> Void
    var onLink: (_ context: Peer, SubSlashlinkLink) -> Void
    var sharedNote: String {
        """
        \(story.entry.excerpt)
        
        \(story.entry.address)
        """
    }
    
    var author: UserProfile {
        story.author
    }
    
    var body: some View {
        Button(
            action: {
                onRequestDetail(
                    story.entry.address,
                    story.entry.excerpt.description
                )
            },
            label: {
                VStack(alignment: .leading, spacing: AppTheme.tightPadding) {
                    // MARK: header
                    HStack(alignment: .top) {
                        // Pad the top of the text to create the expected whitespace
                        // BUT keep the EllipsisLabelView() below aligned to the top of the container
                        // This is important for hitmasking and consistency between story views
                        StoryEntryUserDetailsView(user: author)
                            .padding([.top], AppTheme.padding)
                        
                        Spacer()
                        
                        Menu(
                            content: {
                                ShareLink(item: sharedNote)
                            },
                            label: {
                                EllipsisLabelView()
                            }
                        )
                    }
                    // Omit trailing padding to allow ... hit target to move to top right corner
                    .padding([.leading], AppTheme.padding)
                    
                    // MARK: excerpt
                    SubtextView(
                        subtext: story.entry.excerpt,
                        transcludePreviews: [:],
                        onViewTransclude: { slashlink in
                            onRequestDetail(slashlink, story.entry.excerpt.description)
                        },
                        onTranscludeLink: { context, link in
                            onLink(context, link)
                        }
                    )
                    .padding([.leading, .trailing], AppTheme.padding)
                    // Handle tapped slashlinks in the preview
                    .environment(\.openURL, OpenURLAction { url in
                        
                        guard let subslashlink = url.toSubSlashlinkURL() else {
                            return .systemAction
                        }
                        
                        onLink(story.entry.toPeer(), subslashlink)
                        return .handled
                    })
                    
                    VStack(alignment: .leading) {
                        if story.entry.isTruncated {
                            Text("Show more…")
                                .foregroundColor(.accentColor)
                                .font(.callout)
                        }
                        
                        // MARK: footer
                        HStack(alignment: .center, spacing: AppTheme.unit) {
                            Image(audience: .public)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: AppTheme.unit3, height: AppTheme.unit3)
                            
                            SlashlinkDisplayView(slashlink: Slashlink(
                                peer: author.address.peer,
                                slug: story.entry.address.slug
                            ))
                            .theme(base: .secondary, slug: .secondary)
                            
                            Spacer()
                            
                            Text(
                                NiceDateFormatter.shared.string(
                                    from: story.entry.modified,
                                    relativeTo: Date.now
                                )
                            )
                        }
                        .foregroundColor(.secondary)
                        .font(.caption)
                    }
                    .padding([.leading, .trailing, .bottom], AppTheme.padding)
                }
                .background(Color.background)
                .contentShape(Rectangle())
            }
        )
        .contentShape(.interaction, RectangleCroppedTopRightCorner())
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
                ),
                author: UserProfile.dummyData()
            ),
            onRequestDetail: { _, _ in },
            onLink: { _, _ in }
        )
    }
}
