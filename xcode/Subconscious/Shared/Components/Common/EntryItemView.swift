//
//  EntryItemView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/21.
//

import SwiftUI

/// An entryview suitable for use in lists.
/// Provides a preview/excerpt of the entry.
struct EntryItemView: View {
    var entry: SubtextFile

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            HStack {
                Text(entry.title)
                    .font(Font.appTitle)
                    .lineLimit(2)
                    .foregroundColor(Color.text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(entry.excerpt)
                    .lineLimit(3)
                    .foregroundColor(Color.text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(Slashlink.removeLeadingSlash(entry.slug))
                    .lineLimit(1)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
