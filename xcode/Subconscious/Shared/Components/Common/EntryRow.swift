//
//  EntryItemView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/21.
//

import SwiftUI

/// An EntryRow suitable for use in lists.
/// Provides a preview/excerpt of the entry.
struct EntryRow: View {
    var entry: EntryStub
    var emptyExcerpt = "Empty"
    var highlight: Color = .secondary
    var onLink: (EntryLink) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            SubtextView(
                subtext: entry.excerpt,
                onLink: { link in
                    let rebasedLink = link.rebaseIfNeeded(peer: entry.toPeer())
                    onLink(rebasedLink)
                }
            )
            .font(.callout)
            .multilineTextAlignment(.leading)
            .padding(.bottom, AppTheme.unit2)
            
            HStack(spacing: AppTheme.unit) {
                Image(audience: entry.address.toAudience())
                    .font(.system(size: 12))
                SlashlinkDisplayView(slashlink: entry.address)
                    .theme(base: highlight, slug: highlight)

                Spacer()

                Text(
                    NiceDateFormatter.shared.string(
                        from: entry.modified,
                        relativeTo: Date.now
                    )
                )
                .font(.subheadline)
                .foregroundColor(highlight)
            }
            .font(.callout)
            .lineLimit(1)
            .foregroundColor(highlight)
            .multilineTextAlignment(.leading)
        }
        .tint(highlight)
    }
}

struct EntryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.unit2) {
            EntryRow(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        peer: Peer.did(Did.local),
                        slug: Slug(formatting: "Anything that can be derived should be derived")!
                    ),
                    excerpt: Subtext(
                        markup: """
                              Anything that can be derived should be derived.
                              Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.
                              """
                    ),
                    isTruncated: false,
                    modified: Date.now
                )
            )
            EntryRow(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "@here/anything-that-can-be-derived-should-be-derived"
                    )!,
                    excerpt: Subtext(
                        markup: "Anything that can be derived should be derived. Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply."
                    ),
                    isTruncated: false,
                    modified: Date.now
                )
            )
            EntryRow(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "did:key:abc123/anything-that-can-be-derived-should-be-derived"
                    )!,
                    excerpt: Subtext(
                        markup: "Anything that can be derived should be derived. Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply."
                    ),
                    isTruncated: false,
                    modified: Date.now
                )
            )
            EntryRow(
                entry: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "did:subconscious:local/anything-that-can-be-derived-should-be-derived"
                    )!,
                    excerpt: Subtext(
                        markup: "Anything that can be derived should be derived. Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply."
                    ),
                    isTruncated: false,
                    modified: Date.now
                )
            )
        }
        .padding(AppTheme.unit2)
    }
}
