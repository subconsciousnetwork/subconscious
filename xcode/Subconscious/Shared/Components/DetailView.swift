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
                isKeyboardUp: isEditorFocused,
                content: {
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            GrowableTextViewRepresentable(
                                attributedText: $editorAttributedText,
                                isFocused: $isEditorFocused,
                                selection: $editorSelection,
                                onLink: onEditorLink,
                                fixedWidth: geometry.size.width
                            ).insets(
                                EdgeInsets(
                                    top: AppTheme.padding,
                                    leading: AppTheme.padding,
                                    bottom: AppTheme.padding,
                                    trailing: AppTheme.padding
                                )
                            ).frame(minHeight: geometry.size.height)
                            Divider()
                            BacklinksView(
                                backlinks: backlinks,
                                onActivateBacklink: onCommitSearch
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
            NavigationView {
                VStack {
                    HStack {
                        Spacer()
                    }
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            isLinkSheetPresented = false
                        }) {
                            Text("Cancel")
                        }
                    }
                }
                .searchable(text: $linkSearchText, placement: .toolbar) {
                    ForEach(linkSuggestions, id: \.self) { suggestion in
                        Button(action: {
                            onCommitLinkSearch(suggestion.description)
                        }) {
                            SuggestionLabelView2(suggestion: suggestion)
                        }
                        // We handle submission directly in button action, so
                        // prevent button submit from bubbling up and
                        // triggering a second submit via onSubmit handler.
                        // 2021-09-29 Gordon Brander
                        .submitScope(true)
                    }
                }
                // Catch keyboard sumit.
                // This will also catch button activations within `.searchable`
                // suggestions, by default. Therefore, we `.submitScope()` the
                // suggestions so that this only catches keyboard submissions.
                // 2021-09-29 Gordon Brander
                .onSubmit(of: .search) {
                    onCommitLinkSearch(linkSearchText)
                }
                .navigationTitle("Search Links")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
