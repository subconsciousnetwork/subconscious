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
    var author: UserProfile
    var action: (Slashlink, String) -> Void
    var sharedNote: String {
        """
        \(story.entry.excerpt)
        
        \(story.entry.address)
        """
    }
    
    var body: some View {
        Button(
            action: {
                action(
                    story.entry.address,
                    story.entry.excerpt
                )
            },
            label: {
                VStack(alignment: .leading, spacing: AppTheme.tightPadding) {
                    HStack(alignment: .top, spacing: AppTheme.unit2) {
                        HStack(alignment: .center, spacing: AppTheme.unit2) {
                            ProfilePic(pfp: author.pfp, size: .large)
                            if let name = author.toNameVariant() {
                                PetnameView(name: name, aliases: author.aliases)
                            }
                        }
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
                    .padding([.leading], AppTheme.padding)
                    
                    VStack(spacing: AppTheme.unit2) {
                        ExcerptView(
                            excerpt: story.entry.excerpt,
                            onViewSlashlink: { slashlink in
                                action(slashlink, story.entry.excerpt)
                            }
                        )
                        
                        HStack(alignment: .center, spacing: AppTheme.unit) {
                            Image(audience: .public)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: AppTheme.unit3, height: AppTheme.unit3)
                            
                            SlashlinkDisplayView(slashlink: Slashlink(
                                peer: story.author.address.peer,
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
//        .overlay(RectangleCroppedTopRightCorner().fill(.blue.opacity(0.5)))
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
