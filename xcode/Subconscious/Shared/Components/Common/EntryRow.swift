//
//  EntryItemView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/21.
//

import SwiftUI

/// An EntryRow suitable for use in lists.
/// Provides a preview/excerpt of the entry.
struct EntryRow: View, Equatable {
    var entry: EntryStub
    var emptyExcerpt = "Empty"

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unitHalf) {
            Text(entry.excerpt.isEmpty ? emptyExcerpt : entry.excerpt)
                .lineLimit(2)
                .font(.callout)
                .multilineTextAlignment(.leading)
            HStack(spacing: AppTheme.unit) {
                Image(audience: entry.address.toAudience())
                    .font(.system(size: 12))
                Text(entry.address.slug.description)

                Spacer()

                Text(
                    NiceDateFormatter.shared.string(
                        from: entry.modified,
                        relativeTo: Date.now
                    )
                )
                .font(.subheadline)
                .foregroundColor(Color.secondary)
            }
            .font(.callout)
            .lineLimit(1)
            .foregroundColor(Color.secondary)
            .multilineTextAlignment(.leading)
        }
    }
}

struct EntryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EntryRow(
                entry: EntryStub(
                    address: Slug(formatting: "Anything that can be derived should be derived")!
                        .toLocalMemoAddress(),
                    title: "Anything that can be derived should be derived",
                    excerpt: "Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.",
                    modified: Date.now
                )
            )
            EntryRow(
                entry: EntryStub(
                    address: MemoAddress.public(
                        Slashlink(
                            "@here/anything-that-can-be-derived-should-be-derived"
                        )!
                    ),
                    title: "Anything that can be derived should be derived",
                    excerpt: "Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.",
                    modified: Date.now
                )
            )
        }
    }
}
