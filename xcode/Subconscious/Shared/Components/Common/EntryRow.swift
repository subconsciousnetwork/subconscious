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
    var emptyTitle = "Untitled"
    var emptyExcerpt = "No additional text"

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(
                    !entry.link.title.isEmpty ?
                    entry.link.title :
                    emptyTitle
                )
                .font(.body)
                .foregroundColor(Color.text)
                Spacer()
                Text(
                    NiceDateFormatter.shared.string(
                        from: entry.modified,
                        relativeTo: Date.now
                    )
                )
                .font(.callout)
                .foregroundColor(Color.secondary)
            }
            .lineLimit(1)
            Text(
                entry.excerpt.isEmpty ? emptyExcerpt : entry.excerpt
            )
            .lineLimit(2)
            .font(.callout)
            .multilineTextAlignment(.leading)
            .foregroundColor(Color.secondary)
        }
    }
}

struct EntryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EntryRow(
                entry: EntryStub(
                    link: EntryLink(title: "Anything that can be derived should be derived")!,
                    excerpt: "Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.",
                    modified: Date.now,
                    audience: .local
                )
            )
        }
    }
}
