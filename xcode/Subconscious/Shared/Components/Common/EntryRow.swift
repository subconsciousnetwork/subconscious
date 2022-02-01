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

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            HStack {
                Text(entry.title)
                    .font(Font.appText)
                    .lineLimit(2)
                    .foregroundColor(Color.text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(entry.excerpt)
                    .font(Font.appText)
                    .lineLimit(3)
                    .foregroundColor(Color.secondaryText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
