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
    var emptyText = "Empty"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.title.isEmpty ? emptyText : entry.title)
                    .font(Font.appText)
                    .lineLimit(1)
                    .foregroundColor(Color.text)
                    .multilineTextAlignment(.leading)
                    // Aligns this text's vertical center to icon vertical
                    // center in a label.
                    .frame(minHeight: AppTheme.icon)
                Spacer()
            }
            HStack {
                Text(entry.excerpt.isEmpty ? emptyText : entry.excerpt)
                    .font(Font.appText)
                    .lineLimit(2)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
