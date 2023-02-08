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
                .lineLimit(1)
                .foregroundColor(Color.text)
                .multilineTextAlignment(.leading)
                // Aligns this text's vertical center to icon vertical
                // center in a label.
                .frame(minHeight: AppTheme.icon)
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
            Text(entry.excerpt.isEmpty ? emptyExcerpt : entry.excerpt)
                .lineLimit(1)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.secondary)
            HStack(spacing: AppTheme.unit) {
                AudienceIconView(audience: entry.audience)
                    .font(.system(size: 12))
                Text(entry.slug.description)
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
                    link: EntryLink(title: "Anything that can be derived should be derived")!,
                    excerpt: "Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.",
                    modified: Date.now,
                    audience: .local
                )
            )
            EntryRow(
                entry: EntryStub(
                    link: EntryLink(title: "Anything that can be derived should be derived")!,
                    excerpt: "Insight from Rich Hickey. Practical example: all information in Git is derived. At Git's core, it is simply a linked list of annotated diffs. All commands are derived via diff/patch/apply.",
                    modified: Date.now,
                    audience: .public
                )
            )
        }
    }
}
