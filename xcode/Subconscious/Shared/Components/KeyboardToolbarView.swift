//
//  KeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct KeyboardToolbarView: View {
    @Binding var isSheetPresented: Bool
    @Binding var suggestions: [Suggestion]

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
                Divider()
                if let suggestion = suggestions.first {
                    Button(
                        action: {
                        },
                        label: {
                            Text(suggestion.description)
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
        KeyboardToolbarView(
            isSheetPresented: .constant(false),
            suggestions: .constant([
                .search(
                    EntryLink(
                        title: "An organism is a living system maintaining both a higher level of internal cooperation"
                    )
                )
            ])
        )
    }
}
