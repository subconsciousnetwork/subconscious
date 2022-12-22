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
        VStack(alignment: .leading, spacing: 0) {
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
                .foregroundColor(Color.secondaryText)
            }
            Text(entry.excerpt.isEmpty ? emptyExcerpt : entry.excerpt)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.secondaryText)
            HStack(spacing: AppTheme.unit) {
                Image(systemName: "doc")
                    .font(.system(size: 12))
                Text(entry.slug.description)
            }
            .lineLimit(1)
            .foregroundColor(Color.secondaryText)
            .multilineTextAlignment(.leading)
        }
    }
}
