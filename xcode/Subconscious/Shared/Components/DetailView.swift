//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    @Binding var focus: AppModel.Focus?
    @Binding var editorAttributedText: NSAttributedString
    @Binding var editorSelection: NSRange
    @Binding var isLinkSheetPresented: Bool
    @Binding var linkSearchText: String
    @Binding var linkSuggestions: [Suggestion]
    var backlinks: [SubtextFile]
    var onDone: () -> Void
    var onEditorLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool
    var onCommitSearch: (String) -> Void
    var onCommitLinkSearch: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            PseudoKeyboardToolbarView(
                isKeyboardUp: focus == .editor,
                content: {
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            GrowableAttributedTextViewRepresentable(
                                attributedText: $editorAttributedText,
                                selection: $editorSelection,
                                focus: $focus,
                                field: .editor,
                                onLink: onEditorLink,
                                fixedWidth: geometry.size.width
                            ).insets(
                                EdgeInsets(
                                    top: AppTheme.margin,
                                    leading: AppTheme.margin,
                                    bottom: AppTheme.margin,
                                    trailing: AppTheme.margin
                                )
                            ).frame(
                                minHeight: geometry.size.height / 2
                            )
                            Divider()
                            if backlinks.count > 0 {
                                BacklinksView(
                                    backlinks: backlinks,
                                    onActivateBacklink: onCommitSearch
                                )
                            }
                        }
                    }
                },
                toolbar: {
                    KeyboardToolbarView(
                        isSheetPresented: $isLinkSheetPresented,
                        suggestions: .constant([])
                    )
                }
            )
        }.background(
            Color.background
        ).toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if focus == .editor {
                    Button(
                        action: onDone,
                        label: {
                            Text("Done")
                        }
                    )
                } else {
                    EmptyView()
                }
            }
        }.sheet(
            isPresented: $isLinkSheetPresented,
            onDismiss: {}
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                text: $linkSearchText,
                focus: $focus,
                suggestions: $linkSuggestions,
                onCancel: {
                    isLinkSheetPresented = false
                },
                onCommitLinkSearch: { slug in
                    onCommitLinkSearch(slug)
                }
            )
        }
    }
}
