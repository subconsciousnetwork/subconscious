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
                    .bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(entry.excerpt)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
