//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct DetailView: View {
    @Binding var editorAttributedText: NSAttributedString
    @Binding var isEditorFocused: Bool
    @Binding var editorSelection: NSRange
    @Binding var isLinkSheetPresented: Bool
    @Binding var isLinkSearchFocused: Bool
    @Binding var linkSearchText: String
    @Binding var linkSuggestions: [Suggestion]
    var backlinks: [TextFile]
    var onDone: () -> Void
    var onEditorLink: (
        URL,
        NSAttributedString,
        NSRange,
        UITextItemInteraction
    ) -> Bool
    var onActivateBacklink: (String) -> Void
    var onCommitLinkSearch: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            PseudoKeyboardToolbarView(
                isKeyboardUp: isEditorFocused,
                content: {
                    ScrollView {
                        VStack(spacing: 0) {
                            GrowableTextViewRepresentable(
                                attributedText: $editorAttributedText,
                                isFocused: $isEditorFocused,
                                selection: $editorSelection,
                                onLink: onEditorLink,
                                fixedWidth: geometry.size.width
                            )
                            .insets(
                                EdgeInsets(
                                    top: AppTheme.padding,
                                    leading: AppTheme.padding,
                                    bottom: AppTheme.padding,
                                    trailing: AppTheme.padding
                                )
                            )
                            .frame(minHeight: geometry.size.height)
                            Divider()
                            BacklinksView(
                                backlinks: backlinks,
                                onActivateBacklink: onActivateBacklink
                            )
                        }
                    }
                },
                toolbar: {
                    KeyboardToolbarView(
                        isSheetPresented: $isLinkSheetPresented,
                        suggestions: $linkSuggestions
                    )
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditorFocused {
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
        }
        .sheet(
            isPresented: $isLinkSheetPresented,
            onDismiss: {}
        ) {
            VStack(spacing: 0) {
                SearchBarRepresentable(
                    placeholder: "Search notes",
                    text: $linkSearchText,
                    isFocused: $isLinkSearchFocused,
                    onCommit: onCommitLinkSearch
                )
                SuggestionsView(
                    suggestions: linkSuggestions,
                    action: { suggestion in
                        
                    }
                )
                Spacer()
            }
        }
    }
}
