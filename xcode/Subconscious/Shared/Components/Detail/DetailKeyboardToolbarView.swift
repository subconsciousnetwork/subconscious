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
            HStack(alignment: .center, spacing: Unit.four) {
                Button(
                    action: {
                        isSheetPresented = true
                    },
                    label: {
                        Image(systemName: "magnifyingglass")
                            .frame(
                                width: Unit.icon,
                                height: Unit.icon
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
            .frame(height: Unit.icon, alignment: .center)
            .padding(.horizontal, Unit.padding)
            .padding(.vertical, Unit.tightPadding)
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
                        address: MemoAddress.local(
                            Slug("an-organism-is-a-living-system")!
                        ),
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
