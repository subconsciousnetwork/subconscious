//
//  DetailKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailKeyboardToolbarView: View {
    var onCommit: (Slug) -> Void
    @Binding var isSheetPresented: Bool
    var suggestions: Suggestions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: AppTheme.unit4) {
                Button(
                    action: {
                        isSheetPresented = true
                    },
                    label: {
                        Image(systemName: "magnifyingglass")
                            .frame(
                                width: AppTheme.icon,
                                height: AppTheme.icon
                            )
                    }
                )
                ForEach(suggestions.entries.prefix(2)) { suggestion in
                    Divider()
                    Button(
                        action: {
                            onCommit(suggestion.slug)
                        },
                        label: {
                            Text(suggestion.slug.description)
                                .lineLimit(1)
                        }
                    )
                }
                Spacer()
            }
            .frame(height: AppTheme.icon, alignment: .center)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, AppTheme.tightPadding)
            .background(Color.background)
        }
    }
}

struct KeyboardToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        DetailKeyboardToolbarView(
            onCommit: { slug in },
            isSheetPresented: .constant(false),
            suggestions: Suggestions(
                literal: nil,
                top: nil,
                entries: [
                    EntryLink(
                        slug: Slug("an-organism-is-a-living-system")!,
                        title: "An organism is a living system maintaining both a higher level of internal cooperation"
                    )
                ],
                searches: []
            )
        )
    }
}
