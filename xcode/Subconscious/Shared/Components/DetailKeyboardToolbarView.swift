//
//  DetailKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailKeyboardToolbarView: View {
    @Binding var isSheetPresented: Bool
    var suggestions: [LinkSuggestion]
    var onSelect: (LinkSuggestion) -> Void

    private func barSuggestions() -> ArraySlice<Wikilink> {
        self.suggestions
            .compactMap({ suggestion in
                switch suggestion {
                case let .entry(link):
                    return link
                default:
                    return nil
                }
            })
            .prefix(2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: AppTheme.unit4) {
                Button(
                    action: {
                        isSheetPresented = true
                    },
                    label: {
                        Image(systemName: "link.badge.plus")
                            .frame(
                                width: AppTheme.icon,
                                height: AppTheme.icon
                            )
                    }
                )
                ForEach(self.barSuggestions()) { suggestion in
                    Divider()
                    Button(
                        action: {
                            onSelect(.entry(suggestion))
                        },
                        label: {
                            Text(suggestion.slug.toSentence())
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
            isSheetPresented: .constant(false),
            suggestions: [
                .entry(
                    Wikilink(
                        slug: Slug("an-organism-is-a-living-system")!
                    )
                )
            ],
            onSelect: { suggestion in }
        )
    }
}
