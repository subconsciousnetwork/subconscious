//
//  DetailKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

/// Root toolbar
struct DetailKeyboardToolbarView: View {
    @Binding var isSheetPresented: Bool
    var selectedEntryLinkMarkup: Subtext.EntryLinkMarkup?
    var suggestions: [LinkSuggestion]
    var onSelectLink: (LinkSuggestion) -> Void
    var onInsertWikilink: () -> Void
    var onInsertBold: () -> Void
    var onInsertItalic: () -> Void
    var onInsertCode: () -> Void
    var onDoneEditing: () -> Void

    private var entryLinks: [EntryLink] {
        suggestions.compactMap({ suggestion in
            switch suggestion {
            case let .entry(link):
                return link
            default:
                return nil
            }
        })
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
                        Image(systemName: "magnifyingglass")
                            .frame(
                                width: AppTheme.icon,
                                height: AppTheme.icon
                            )
                    }
                )
                Divider()
                if selectedEntryLinkMarkup != nil {
                    EntryLinkSuggestionBarView(
                        links: entryLinks,
                        onSelectLink: onSelectLink
                    )
                } else {
                    InlineFormattingBarView(
                        onInsertWikilink: onInsertWikilink,
                        onInsertBold: onInsertBold,
                        onInsertItalic: onInsertItalic,
                        onInsertCode: onInsertCode
                    )
                }
                Spacer()
                Button(
                    action: onDoneEditing,
                    label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                )
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
                    EntryLink(
                        slug: Slug("an-organism-is-a-living-system")!
                    )
                )
            ],
            onSelectLink: { suggestion in },
            onInsertWikilink: {},
            onInsertBold: {},
            onInsertItalic: {},
            onInsertCode: {},
            onDoneEditing: {}
        )
    }
}
