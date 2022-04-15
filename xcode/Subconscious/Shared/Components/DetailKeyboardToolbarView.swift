//
//  DetailKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

/// Toolbar in wikilink autocomplete mode
struct DetailKeyboardWikilinkToolbarView: View {
    @Binding var isSheetPresented: Bool
    var links: [Wikilink]
    var onSelectLink: (LinkSuggestion) -> Void

    var body: some View {
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
            ForEach(links) { link in
                Divider()
                Button(
                    action: {
                        onSelectLink(.entry(link))
                    },
                    label: {
                        Text(link.text)
                            .lineLimit(1)
                    }
                )
            }
            Spacer()
        }
    }
}

/// Toolbar in default mode
struct DetailKeyboardDefaultToolbarView: View {
    @Binding var isSheetPresented: Bool
    var onInsertWikilink: () -> Void
    var onDoneEditing: () -> Void

    var body: some View {
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
            Button(
                action: onInsertWikilink,
                label: {
                    Image(systemName: "link")
                        .frame(
                            width: AppTheme.icon,
                            height: AppTheme.icon
                        )
                }
            )
            Spacer()
            Button(
                action: onDoneEditing,
                label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            )
        }
    }
}

/// Root toolbar
struct DetailKeyboardToolbarView: View {
    @Binding var isSheetPresented: Bool
    var selectedWikilink: Subtext.Wikilink?
    var suggestions: [LinkSuggestion]
    var onSelectLink: (LinkSuggestion) -> Void
    var onInsertWikilink: () -> Void
    var onDoneEditing: () -> Void

    private func wikilinkSuggestions() -> [Wikilink] {
        let wikilinks: [Wikilink] = suggestions.compactMap({ suggestion in
            switch suggestion {
            case let .entry(link):
                return link
            default:
                return nil
            }
        })
        return Array(wikilinks.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            VStack {
                if selectedWikilink != nil {
                    DetailKeyboardWikilinkToolbarView(
                        isSheetPresented: $isSheetPresented,
                        links: self.wikilinkSuggestions(),
                        onSelectLink: onSelectLink
                    )
                } else {
                    DetailKeyboardDefaultToolbarView(
                        isSheetPresented: $isSheetPresented,
                        onInsertWikilink: onInsertWikilink,
                        onDoneEditing: onDoneEditing
                    )
                }
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
            onSelectLink: { suggestion in },
            onInsertWikilink: {},
            onDoneEditing: {}
        )
    }
}
