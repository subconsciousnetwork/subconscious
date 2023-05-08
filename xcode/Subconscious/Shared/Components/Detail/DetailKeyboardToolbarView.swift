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
    var selectedShortlink: Subtext.Shortlink?
    var suggestions: [LinkSuggestion]
    var onSelectLinkCompletion: (EntryLink) -> Void
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
                switch selectedShortlink {
                case .wikilink:
                    WikilinkBarView(
                        links: entryLinks,
                        onSelectLink: onSelectLinkCompletion
                    )
                case .slashlink:
                    SlashlinkBarView(
                        links: entryLinks,
                        onSelectLink: onSelectLinkCompletion
                    )
                case .none:
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
                        address: Slug("an-organism-is-a-living-system")!
                            .toLocalSlashlink(),
                        title: "An organism is a living system"
                    )
                )
            ],
            onSelectLinkCompletion: { _ in },
            onInsertWikilink: {},
            onInsertBold: {},
            onInsertItalic: {},
            onInsertCode: {},
            onDoneEditing: {}
        )
    }
}
