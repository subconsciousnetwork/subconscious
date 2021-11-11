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
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            HStack {
                Text(entry.title)
                    .bold()
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
                Text(Slashlink.addLeadingSlash(entry.slug))
                    .lineLimit(1)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
